package epidemicspreading;



import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
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
		
		// General parameters
		String network = "BA";
		int N = 500;
		// ER parameters
		double p = 0.4;
		// BA parameters
		int m0 = 5;
		int m = 4;
		// SIS parameters
		double betaStart = 0;
		double betaEnd = 1;
		double betaInc = 0.02;
		int mu = 1;
		double rho0 = 0.2;
		int nRep = 100;
		int tMax = 1000;
		int tTrans = 900;
		//
		
		int betaN = (int) ( (betaEnd - betaStart) / betaInc );
		double[] beta = new double[betaN];
		beta[0] = betaStart;
		for(int i = 1; i < betaN; i++) {
			beta[i] = beta[i-1] + betaInc;
		}
		
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

	}
}
