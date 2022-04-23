package epidemicspreading;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Random;
import java.util.Set;

import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;

public final class MonteCarlo {
	private Graph<String, DefaultEdge> graph;
	private int N;
	private Set<String> vertexSet;
	private double[] beta;
	private int mu;
	double rho0;
	int nRep;
	int tMax;
	int tTrans;
	
	// Returns the average fraction of infected nodes over nRep simulations
	// for each beta value
	public static double[] fit(double[] beta, double rho0, int nRep, int tMax, int tTrans) {
		double[] avgRho = new double[beta.length];
		double[] rho = new double[tMax];
		
		return avgRho;
	}
	
	// Returns the average fraction of infected nodes over nRep simulations
	// for a specific value of beta
	private double avgSimulation(double beta) {
		double sum = 0;
		for(int i = 0; i < nRep; i++) {
			sum += simulation(beta);
		}
		return sum/nRep;
		
	}

	// Returns the average fraction of infected nodes in the stationary state
	// for a specific value of beta
	private double simulation(double beta) {
		
		// Create initial state with rh0 percentage of infected
		List<String> values = new ArrayList<String>();
		int nInfected = (int) (N*rho0);
		for(int i = 0; i < nInfected; i++) {
			values.add("I");
		}
		for(int i = nInfected; i < N; i++) {
			values.add("S");
		}
        Collections.shuffle(values);
        final Iterator<String> vIter = values.iterator();
        
		HashMap<String, String> initialState = new HashMap<>();
		for (String k : vertexSet) {
			initialState.put(k, vIter.next());
		}

		// Run tMax steps
		double sum = 0;
		HashMap<String, String> state = initialState;
		for(int i = 0; i < tMax; i++) {
			state = step(beta, state);
			sum += stateToRho(state);
		}
		return sum/nRep;
	}
	
	private HashMap<String, String> step(double beta, HashMap<String, String> state) {
		HashMap<String, String> newState = new HashMap<>();
		Random r = new Random();
		for (String k : vertexSet) {
			String v = null;
			if(state.get(k) == "I") {
				v = r.nextDouble() >= mu ? "I" : "S";
			}
			if(state.get(k) == "S") {
				//TODO
				v = "0";
			}
			newState.put(k, v);
		}
		return newState;
		
	}
	
	private double stateToRho(HashMap<String, String> state) {
		//TODO count occurrence of I in state and divide by N
		return 0.;
	}
	
	

}
