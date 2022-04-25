package epidemicspreading;


import org.apache.commons.io.FileUtils;
import org.jgrapht.Graph;
import org.jgrapht.graph.DefaultEdge;
import org.jgrapht.graph.SimpleGraph;
import org.jgrapht.nio.GraphImporter;
import org.jgrapht.nio.graphml.GraphMLExporter;
import org.jgrapht.nio.graphml.GraphMLImporter;
import org.jgrapht.util.SupplierUtil;

import javax.swing.*;
import javax.swing.filechooser.FileFilter;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintStream;
import java.nio.file.Paths;
import java.text.DecimalFormat;
import java.text.NumberFormat;
import java.util.Arrays;
import java.util.Locale;


public class Runner {


    public static void main(String[] args) throws IOException {
        String resultsPath = Paths.get(System.getProperty("user.dir"), "output", "results").toString();
        //noinspection ResultOfMethodCallIgnored
        new File(resultsPath).mkdirs();

        // General parameters
//        String network = "ER";
//        int N = 500;
        // ER parameters
//        double p = 0.1;
//        creatERGraph(N, p);
        // BA parameters
//        int m0 = 10;
//        int m = 5;
//        creatBAGraph(N, m0, m);
//        creatScaleFreeGraph(N);

        File f = selectNet();
        if (f != null) {
            Graph<String, DefaultEdge> graph = readGraph(f);
            String fn = f.getName().substring(0, f.getName().lastIndexOf("."));
            System.out.println("Simulating epidemic spreading in network " + fn);
            System.out.println();

            // SIS parameters
            double betaStart = 0, betaEnd = 1, betaInc = 0.02;
            double[] muList = {0.1, 0.5, 0.9};
            double[][] betaTrans = {{0.0, 0.0, 0.002}, {0.0, 0.0, 0.002}, {0.0, 0.0, 0.002}};
            double rho0 = 0.2;
            int nRep = 100;
            int tMax = 1000;
            int tTrans = 900;

            for (int k = 0; k < muList.length; k++) {
                double mu = muList[k];
                System.out.printf("Fitting for mu %.1f%n", mu);
                // Beta with an incremented number of values around
                // the transition area
                double betaStartTrans = betaTrans[k][0], betaEndTrans = betaTrans[k][1], betaIncTrans = betaTrans[k][2];
                int betaN;
                if (betaStartTrans == betaEndTrans) {
                    betaN = (int) ((betaEnd - betaStart) / betaInc) + 1;
                } else {
                    betaN = (int) (Math.round((betaStartTrans - betaStart) / betaInc) + Math.round(
                        (betaEndTrans - betaStartTrans) / betaIncTrans) + Math.round((betaEnd - betaEndTrans)/betaInc));
                }

                double[] beta = new double[betaN];
                beta[0] = betaStart;
                double inc;

                for (int i = 1; i < betaN; i++) {
                    if (betaStartTrans != betaEndTrans && betaStartTrans <= beta[i - 1] && beta[i - 1] <= betaEndTrans) {
                        inc = betaIncTrans;
                    } else {
                        inc = betaInc;
                    }
                    beta[i] = beta[i - 1] + inc;
                }

                // Simple beta
//                int betaN = (int) ((betaEnd - betaStart) / betaInc) + 1;
//                double[] beta = new double[betaN];
//                beta[0] = betaStart;
//                for (int i = 1; i < betaN; i++) {
//                    beta[i] = beta[i - 1] + betaInc;
//                }

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
                String resultsDir = Paths.get(resultsPath, fn, String.format(Locale.UK, "mu-%.1f", mu)).toString();
                f = new File(resultsDir);
                if (!f.mkdirs()) {
                    FileUtils.cleanDirectory(f);
                }

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
                    String simBetaFile = Paths.get(resultsDir, String.format(Locale.UK, "avgSim-%.3f.txt", beta[i]))
                        .toString();
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
    }

    private static File selectNet() {
        final JFileChooser fc = new JFileChooser(Paths.get(System.getProperty("user.dir"), "A4-networks").toString());
        fc.setFileFilter(new FileFilter() {
            @Override
            public boolean accept(File file) {
                if (file.isDirectory()) {
                    return true;
                } else {
                    return file.getName().toLowerCase(Locale.ROOT).endsWith(".xml");
                }
            }

            @Override
            public String getDescription() {
                return "GraphML files (*.xml)";
            }
        });
        int r = fc.showOpenDialog(null);
        if (r == JFileChooser.APPROVE_OPTION) {
            return fc.getSelectedFile();
        }
        return null;

    }

    private static Graph<String, DefaultEdge> readGraph(File file) {
        Graph<String, DefaultEdge> graph = new SimpleGraph<>(GenerateGraph.getvSupplier(),
            SupplierUtil.createDefaultEdgeSupplier(), false);
        if (file.getName().contains("airports") || file.getName().contains("dolphins")) {
            graph = new SimpleGraph<>(GenerateGraph.getvSupplier(), SupplierUtil.createDefaultEdgeSupplier(), true);
        }
        GraphImporter<String, DefaultEdge> importer = new GraphMLImporter<>();
        importer.importGraph(graph, file);
        return graph;
    }

    public static void creatERGraph(int n, double p) {
        String networksPath = Paths.get(System.getProperty("user.dir"), "A4-networks", "model").toString();
        //noinspection ResultOfMethodCallIgnored
        new File(networksPath).mkdirs();

        Graph<String, DefaultEdge> graph = GenerateGraph.ER(n, p);
        NumberFormat formatter = new DecimalFormat("#.##");
        String fn = String.format(Locale.UK, "%s-%d-%s", "ER", n, formatter.format(p));

        saveGraph(networksPath, graph, fn);
    }

    public static void creatBAGraph(int n, int m0, int m) {
        String networksPath = Paths.get(System.getProperty("user.dir"), "A4-networks", "model").toString();
        //noinspection ResultOfMethodCallIgnored
        new File(networksPath).mkdirs();

        Graph<String, DefaultEdge> graph = GenerateGraph.BA(m0, m, n);
        String fn = String.format("%s-%d-%d-%d", "BA", n, m0, m);

        saveGraph(networksPath, graph, fn);
    }

    public static void creatScaleFreeGraph(int n) {
        String networksPath = Paths.get(System.getProperty("user.dir"), "A4-networks", "model").toString();
        //noinspection ResultOfMethodCallIgnored
        new File(networksPath).mkdirs();

        Graph<String, DefaultEdge> graph = GenerateGraph.ScaleFree(n);
        String fn = String.format("%s-%d", "SF", n);

        saveGraph(networksPath, graph, fn);
    }

    private static void saveGraph(String networksPath, Graph<String, DefaultEdge> graph, String fn) {
        System.out.println(graph);
        float avgDegree = 0;
        for (String v : graph.vertexSet()) {
            avgDegree += graph.degreeOf(v);
        }
        avgDegree /= graph.vertexSet().size();
        System.out.printf("Average degree: %f", avgDegree);
        String roundAvgDegree = Integer.toString(Math.round(avgDegree));

        String networkFile = Paths.get(networksPath, fn + "-" + roundAvgDegree + ".net").toString();
        String graphMLFile = Paths.get(networksPath, fn + "-" + roundAvgDegree + ".xml").toString();
        GraphMLExporter<String, DefaultEdge> exporter = new GraphMLExporter<>();
        try {
            exporter.exportGraph(graph, new FileWriter(graphMLFile));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        GenerateGraph.savePajek(graph, networkFile);
    }
}
