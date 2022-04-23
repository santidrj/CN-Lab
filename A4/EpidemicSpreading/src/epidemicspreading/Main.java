package epidemicspreading;



import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.Set;
import java.util.SortedSet;
import java.nio.file.Path;
import java.nio.file.Paths;

import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;



public class Main {
	
	public static void main(String[] args) throws IOException {
		
		String networksPath = Paths.get("src", "epidemicspreading", "networks").toString();
		
		String network = "BA";
		int N = 500;
		// ER parameters
		double p = 0.4;
		// BA parameters
		int m0 = 5;
		int m = 4;
		
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

	}

}
