package epidemicspreading;

import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Objects;
import java.util.Random;
import java.util.Set;

public class MonteCarlo {
    private Graph<String, DefaultEdge> graph;
    private int N;
    private Set<String> vertexSet;
    private double[] beta;
    private double mu;
    private double rho0;
    private int nRep;
    private int tMax;
    private int tTrans;

    public MonteCarlo(Graph<String, DefaultEdge> graph, double[] beta, double mu, double rho0, int nRep, int tMax,
                      int tTrans) {
        this.graph = graph;
        this.vertexSet = this.graph.vertexSet();
        this.N = this.vertexSet.size();
        this.beta = beta;
        this.mu = mu;
        this.rho0 = rho0;
        this.nRep = nRep;
        this.tMax = tMax;
        this.tTrans = tTrans;
    }

    public void setGraph(Graph<String, DefaultEdge> graph) {
        this.graph = graph;
        this.vertexSet = this.graph.vertexSet();
        this.N = this.vertexSet.size();
    }

    public void setBeta(double[] beta) {
        this.beta = beta;
    }

    public void setMu(double mu) {
        this.mu = mu;
    }

    public void setRho0(double rho0) {
        this.rho0 = rho0;
    }

    public void setnRep(int nRep) {
        this.nRep = nRep;
    }

    public void settMax(int tMax) {
        this.tMax = tMax;
    }

    public void settTrans(int tTrans) {
        this.tTrans = tTrans;
    }

    /**
     * Run the Monte Carlo simulation and return the average Rho and simulation for each value of {@link #beta}.
     *
     * @return {@code Object[]} with the average Rho as {@code double[]} and the average simulations as {@code
     * double[][]}.
     */
    public Object[] fit() {
        double[] avgRho = new double[beta.length];
        double[][] avgSim = new double[beta.length][tMax];

        // The script starts printing from the second line onwards
        System.out.println("...");

        for (int b = 0; b < beta.length; b++) {
            System.out.printf("Fitting for beta %f%n", beta[b]);
            double[] simBeta = avgSimulation(beta[b]);
            avgRho[b] = avgStationary(simBeta);
            avgSim[b] = simBeta;
        }
        return new Object[]{avgRho, avgSim};
    }

    // Runs nRep simulations and computes the average rho at each time step
    // for a given value of beta (computes the "average simulation" we will plot later)
    private double[] avgSimulation(double beta) {
        double[] rho = new double[tMax];
        for (int i = 0; i < nRep; i++) {
            rho = sumTwoArrays(rho, simulation(beta));
        }
        return divideArrayByInteger(rho, nRep);
    }

    // Computes rho at each time step of a simulation for a given value of beta
    private double[] simulation(double beta) {

        // Create initial state with rh0 percentage of infected
        List<String> values = new ArrayList<>();
        int nInfected = (int) (N * rho0);
        for (int i = 0; i < nInfected; i++) {
            values.add("I");
        }
        for (int i = nInfected; i < N; i++) {
            values.add("S");
        }
        Collections.shuffle(values);
        final Iterator<String> vIter = values.iterator();

        HashMap<String, String> initialState = new HashMap<>();
        for (String k : vertexSet) {
            initialState.put(k, vIter.next());
        }

        // Run tMax steps
        double[] rho = new double[tMax];
        rho[0] = rho0;
        HashMap<String, String> state = initialState;
        for (int i = 1; i < tMax; i++) {
            state = step(beta, state);
            rho[i] = stateToRho(state);
        }

        return rho;
    }

    // Computes the next state
    private HashMap<String, String> step(double beta, HashMap<String, String> state) {
        HashMap<String, String> newState = new HashMap<>();
        Random r = new Random();
        for (String k : vertexSet) {
            String newValue = null;
            String nodeState = state.get(k);

            switch (nodeState) {
                case "I":
                    newValue = r.nextDouble() >= mu ? "I" : "S";
                    break;
                case "S":
                    int nInfected = countInfected(k, state);
                    newValue = r.nextDouble() >= Math.pow((1 - beta), nInfected) ? "I" : "S";
                    break;
            }

            newState.put(k, newValue);
        }
        return newState;
    }

    // Counts occurrences of I in a state and returns rho
    private double stateToRho(HashMap<String, String> state) {
        int count = Collections.frequency(state.values(), "I");
        return (double) count / N;
    }

    // Returns the number of infected neighbors for a given node
    private int countInfected(String node, HashMap<String, String> state) {
        int nInfected = 0;
        for (DefaultEdge edge : graph.edgesOf(node)) {
            String source = graph.getEdgeSource(edge);
            String target = graph.getEdgeTarget(edge);
            String neighbor = !Objects.equals(source, node) ? source : target;
            if (Objects.equals(state.get(neighbor), "I")) {
                nInfected += 1;
            }
        }
        return nInfected;
    }

    private double avgStationary(double[] sim) {
        double sum = 0;
        for (int i = tTrans; i < tMax; i++) {
            sum += sim[i];
        }
        return sum / (tMax - tTrans);
    }

    private double[] sumTwoArrays(double[] arr1, double[] arr2) {
        int l = arr1.length;
        double[] arr3 = new double[l];
        for (int i = 0; i < l; i++) {
            arr3[i] = arr1[i] + arr2[i];
        }
        return arr3;
    }

    private double[] divideArrayByInteger(double[] arr, int n) {
        double[] newArr = new double[arr.length];
        for (int i = 0; i < arr.length; i++) {
            newArr[i] = arr[i] / n;
        }
        return newArr;
    }


}
