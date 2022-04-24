package epidemicspreading;

import org.jgrapht.Graph;
import org.jgrapht.generate.BarabasiAlbertGraphGenerator;
import org.jgrapht.generate.GnpRandomGraphGenerator;
import org.jgrapht.graph.DefaultEdge;
import org.jgrapht.graph.SimpleGraph;
import org.jgrapht.util.SupplierUtil;

import java.io.FileNotFoundException;
import java.io.PrintStream;
import java.util.Set;
import java.util.function.Supplier;


public class GenerateGraph {

    // Create the VertexFactory so the generator can create vertices
    private static final Supplier<String> vSupplier = new Supplier<>() {
        private int id = 0;

        @Override
        public String get() {
            return Integer.toString(++id);
        }
    };

    /**
     * public static String toPajekEdge(String edge, int w) {
     * Pattern p = Pattern.compile("\\d+");
     * Matcher m = p.matcher(edge);
     * String s = "";
     * <p>
     * while(m.find()) {
     * s = s + m.group() + " ";
     * }
     * <p>
     * s = s + Integer.toString(w);
     * <p>
     * return s;
     * }
     **/

    public static void savePajek(Graph<String, DefaultEdge> graph, String path) {
        Set<String> vertexSet = graph.vertexSet();
        Set<DefaultEdge> edgeSet = graph.edgeSet();

        try (PrintStream fileStream = new PrintStream(path)) {

            fileStream.printf("*Vertices %d%n", vertexSet.size());
            int i = 0;
            for (String vertex : graph.vertexSet()) {
                fileStream.printf("%d %s%n", ++i, vertex);
            }

            fileStream.println("*Edges");
            for (DefaultEdge edge : graph.edgeSet()) {
                String source = graph.getEdgeSource(edge);
                String target = graph.getEdgeTarget(edge);
                fileStream.printf("%s %s %s%n", source, target, "1");
            }
        } catch (FileNotFoundException | SecurityException e) {
            System.out.println(e.getMessage());
        }

    }


    public static Graph<String, DefaultEdge> ER(int n, double p) {

        // Create the graph object
        Graph<String, DefaultEdge> graph = new SimpleGraph<>(vSupplier, SupplierUtil.createDefaultEdgeSupplier(),
            false);

        // Create the generator object
        GnpRandomGraphGenerator<String, DefaultEdge> generator = new GnpRandomGraphGenerator<>(n, p);

        // Use the generator object to make a graph
        generator.generateGraph(graph);

        return graph;

    }


    public static Graph<String, DefaultEdge> BA(int m0, int m, int n) {

        // Create the graph object
        Graph<String, DefaultEdge> graph = new SimpleGraph<>(vSupplier, SupplierUtil.createDefaultEdgeSupplier(),
            false);

        // Create the generator object
        BarabasiAlbertGraphGenerator<String, DefaultEdge> generator = new BarabasiAlbertGraphGenerator<>(m0, m, n);

        // Use the generator object to make a graph
        generator.generateGraph(graph);

        return graph;

    }

}
