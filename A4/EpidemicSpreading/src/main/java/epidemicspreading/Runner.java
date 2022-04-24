package epidemicspreading;


import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Locale;


public class Runner {

    public static void main(String[] args) {

        String networksPath = Paths.get(System.getProperty("user.dir"), "output", "networks").toString();
        new File(networksPath).mkdirs();
        String resultsPath = Paths.get(System.getProperty("user.dir"), "output", "results").toString();
        new File(resultsPath).mkdirs();

        // General parameters
        String network = "BA";
        int N = 50;
        // ER parameters
        double p = 0.4;
        // BA parameters
        int m0 = 5;
        int m = 4;
        // SIS parameters
        double betaStart = 0, betaEnd = 1, betaInc = 0.02;
        double mu = 0.4;
        double rho0 = 0.2;
        int nRep = 100;
        int tMax = 1000;
        int tTrans = 900;
        //


        // Beta with an incremented number of values around
        // the transition area
        double betaStartTrans = 0.05, betaEndTrans = 0.1, betaIncTrans = 0.002;
        int betaN = (int) (
            ((betaStartTrans - betaStart) / betaInc) + ((betaEndTrans - betaStartTrans) / betaIncTrans) + (
                (betaEnd - betaEndTrans) / betaInc) - 3);

        double[] beta = new double[betaN];
        beta[0] = betaStart;
        double inc;

        for (int i = 1; i < betaN; i++) {
            if (betaStartTrans <= beta[i - 1] & beta[i - 1] <= betaEndTrans) {
                inc = betaIncTrans;
            } else {
                inc = betaInc;
            }
            beta[i] = beta[i - 1] + inc;
        }

        /*
         // Simple beta
         int betaN = (int) ( (betaEnd - betaStart) / betaInc ) + 1;
         double[] beta = new double[betaN];
         beta[0] = betaStart;
         for(int i = 1; i < betaN; i++) {
         beta[i] = beta[i-1] + betaInc;
         }
         */

        Graph<String, DefaultEdge> graph = null;
        String fn = null;

        switch (network) {
            case "BA":
                graph = GenerateGraph.BA(m0, m, N);
                fn = String.format("%s-%d-%d-%d", network, N, m0, m);
                break;
            case "ER":
                graph = GenerateGraph.ER(N, p);
                fn = String.format("%s-%d-%f", network, N, p);
                break;
        }

        System.out.print(graph);

        String networkFile = Paths.get(networksPath, fn + ".net").toString();
        GenerateGraph.savePajek(graph, networkFile);

        MonteCarlo mc = new MonteCarlo(graph, beta, mu, rho0, nRep, tMax, tTrans);

        Object[] results = mc.fit();
        double[] avgRho = (double[]) results[0];
        double[][] avgSim = (double[][]) results[1];

        System.out.println("AvgRho:");
        System.out.println(Arrays.toString(avgRho));
        System.out.println("Beta:");
        System.out.println(Arrays.toString(beta));
        System.out.println("Done");

        // Save results
        String resultsDir = Paths.get(resultsPath, fn).toString();
        File f = new File(resultsDir);
        f.mkdir();

        String betaFile = Paths.get(resultsDir, "beta.txt").toString();
        try (PrintStream betaStream = new PrintStream(betaFile)) {
            for (double b : beta) {
                betaStream.println(b);
            }
        } catch (FileNotFoundException | SecurityException e) {
            System.out.println(e.getMessage());
        }

        String avgRhoFile = Paths.get(resultsDir, "avgRho.txt").toString();
        try (PrintStream avgRhoStream = new PrintStream(avgRhoFile)) {
            for (double rho : avgRho) {
                avgRhoStream.println(rho);
            }
        } catch (FileNotFoundException | SecurityException e) {
            System.out.println(e.getMessage());
        }

        for (int i = 0; i < avgSim.length; i++) {
            String simBetaFile = Paths.get(resultsDir, String.format(Locale.UK, "avgSim-%.3f.txt", beta[i])).toString();
            try (PrintStream simBetaStream = new PrintStream(simBetaFile)) {
                for (double rhoT : avgSim[i]) {
                    simBetaStream.println(rhoT);
                }
            } catch (FileNotFoundException | SecurityException e) {
                System.out.println(e.getMessage());
            }
        }
    }
}
