package epidemicspreading;



import java.io.File;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.SortedSet;
import java.util.stream.Collectors;
import java.util.stream.DoubleStream;
import java.util.stream.IntStream;
import java.util.stream.Stream;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;



public class Main {
	
	public static void main(String[] args) throws IOException {
		
		String networksPath = Paths.get("src", "epidemicspreading", "networks").toString();
		String resultsPath = Paths.get("src", "epidemicspreading", "results").toString();
		
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
		

		// Beta with a incremented number of values around
		// the transition area
		double betaStartTrans = 0.05, betaEndTrans = 0.1, betaIncTrans = 0.002;
		int betaN = (int) ( 
						( (betaStartTrans - betaStart) / betaInc ) 
						+ ( (betaEndTrans - betaStartTrans) / betaIncTrans )
		                + ( (betaEnd - betaEndTrans) / betaInc )
		                -3
		                );
		
		double[] beta = new double[betaN];
		beta[0] = betaStart;
		double inc = 0;
		
		for(int i = 1; i < betaN; i++) {
			if(betaStartTrans <= beta[i-1] & beta[i-1] <= betaEndTrans) {
				inc = betaIncTrans;
			} else {
				inc = betaInc;
			}
			beta[i] = beta[i-1] + inc;
		}

		/**
		// Simple beta
		int betaN = (int) ( (betaEnd - betaStart) / betaInc ) + 1;
		double[] beta = new double[betaN];
		beta[0] = betaStart;
		for(int i = 1; i < betaN; i++) {
			beta[i] = beta[i-1] + betaInc;
		}
		**/

		Graph<String, DefaultEdge> graph = null;
		String fn = null;
		
		switch(network) {
			case "BA":
				graph = GenerateGraph.BA(m0, m, N);
				fn = String.format("%s-%d-%d-%d", network, N, m0, m);
				break;
			case "ER":
				graph = GenerateGraph.ER(N, p);
				fn = String.format("%s-%d-%d-%d", network, N, p);
				break;
		}
		
		System.out.print(graph.toString());
		
		String networkFile =  Paths.get(networksPath, fn+".net").toString();
		GenerateGraph.savePajek(graph, networkFile);
		
		MonteCarlo mc = new MonteCarlo();
		mc.setGraph(graph);
		mc.setBeta(beta);
		mc.setMu(mu);
		mc.setRho0(rho0);
		mc.setnRep(nRep);
		mc.settMax(tMax);
		mc.settTrans(tTrans);
		
		Object[] results = mc.fit();
		double[] avgRho = (double[]) results[0];
		double[][] avgSim = (double[][]) results[1];
		
		System.out.println("AvgRho:");
		System.out.println(Arrays.toString(avgRho));
		System.out.println("Beta:");
		System.out.println(Arrays.toString(beta));
		System.out.println("Done");
		
		// Save results
		String resultsDir =  Paths.get(resultsPath, fn).toString();
		File f = new File(resultsDir);
		f.mkdir();
		
		String betaFile =  Paths.get(resultsDir, "beta.txt").toString();
		PrintStream betaStream = new PrintStream(new File(betaFile));
		for(double b: beta) {
			betaStream.println(b);
		}
		
		String avgRhoFile =  Paths.get(resultsDir, "avgRho.txt").toString();
		PrintStream avgRhoStream = new PrintStream(new File(avgRhoFile));
		for(double rho: avgRho) {
			avgRhoStream.println(rho);
		}
		
		for(int i = 0; i < avgSim.length; i++) {
			String simBetaFile =  Paths.get(resultsDir, String.format(Locale.UK, "avgSim-%.3f.txt", beta[i])).toString();
			PrintStream simBetaStream = new PrintStream(new File(simBetaFile));
			for(double rhoT: avgSim[i]) {
				simBetaStream.println(rhoT);
			}
		}
	}
}
