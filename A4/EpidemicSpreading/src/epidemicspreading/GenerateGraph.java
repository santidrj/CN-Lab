package epidemicspreading;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Arrays;
import java.util.Set;
import java.util.function.Supplier;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.jgrapht.*;

import org.jgrapht.generate.*;
import org.jgrapht.graph.*;
import org.jgrapht.util.SupplierUtil;


public final class GenerateGraph {
	
    // Create the VertexFactory so the generator can create vertices
    private static Supplier<String> vSupplier = new Supplier<String>()
    {
        private int id = 0;

        @Override
        public String get()
        {
            return Integer.toString(++id);
        }
    };
/**
    public static String toPajekEdge(String edge, int w) {
        Pattern p = Pattern.compile("\\d+");
        Matcher m = p.matcher(edge);
        String s = "";
        
        while(m.find()) {
            s = s + m.group() + " ";
        }
        
        s = s + Integer.toString(w);
        
        return s;
    }

**/

    public static void savePajek(Graph<String, DefaultEdge> graph, String path) throws IOException {
    	Set<String> vertexSet = graph.vertexSet();
    	Set<DefaultEdge> edgeSet = graph.edgeSet();
    	
    	PrintStream fileStream = new PrintStream(new File(path));
	
    	fileStream.println(String.format("*Vertices %d", vertexSet.size()));
    	int i = 0;
    	for(String vertex: graph.vertexSet()) {
    		fileStream.println(String.format("%d %s", ++i, vertex));
    	}

    	fileStream.println("*Edges");
    	for(DefaultEdge edge: graph.edgeSet()) {
    		String source = graph.getEdgeSource(edge);
    		String target = graph.getEdgeTarget(edge);
    		fileStream.println(String.format("%s %s %s", source, target, "1"));
    	}

    }

    
	public static Graph<String, DefaultEdge> ER(int n, double p) {
		
		// Create the graph object
		Graph<String, DefaultEdge> graph =
            new SimpleGraph<>(vSupplier, SupplierUtil.createDefaultEdgeSupplier(), false);
	    
	    // Create the generator object
	    GnpRandomGraphGenerator<String, DefaultEdge> generator = 
	    		new GnpRandomGraphGenerator<>(n, p);
	    
        // Use the generator object to make a graph
        generator.generateGraph(graph);
        
        return graph;
		
		}
	
	
	public static Graph<String, DefaultEdge> BA(int m0, int m, int n) {
		
		// Create the graph object
		Graph<String, DefaultEdge> graph =
            new SimpleGraph<>(vSupplier, SupplierUtil.createDefaultEdgeSupplier(), false);
	    
	    // Create the generator object
		BarabasiAlbertGraphGenerator<String, DefaultEdge> generator = 
	    		new BarabasiAlbertGraphGenerator<>(m0, m, n);
	    
        // Use the generator object to make a graph
        generator.generateGraph(graph);
        
        return graph;
		
		}
		
	}