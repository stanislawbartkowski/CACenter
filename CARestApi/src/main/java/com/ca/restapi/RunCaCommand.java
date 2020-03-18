package com.ca.restapi;

import com.rest.restservice.RestLogger;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.function.Consumer;
import java.util.logging.Level;


class RunCaCommand {

    //private static final String CA = "/home/sbartkowski/work/CACenter/ca.sh";


    private static String CA;

    public static void setCA(String CA) {
        RunCaCommand.CA = CA;
    }

    private static class StreamGobbler implements Runnable {
        private InputStream inputStream;
        private Consumer<String> consumer;

        public StreamGobbler(InputStream inputStream, Consumer<String> consumer) {
            this.inputStream = inputStream;
            this.consumer = consumer;
        }

        @Override
        public void run() {
            try {
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {
                    String line = null;
                   while ((line = reader.readLine()) != null ) {
                       consumer.accept(line);
                   }
                }
            } catch (IOException e) {
                String message = "Error while reading line from the process " + CA;
                RestLogger.L.log(Level.SEVERE,message,e);
            }
        }
    }

    static int run(String... pars) throws IOException, InterruptedException {

        // array to list
        List<String> cpars = new ArrayList<>();
        cpars.add(CA);
        for (String s : pars) cpars.add(s);
        ProcessBuilder builder = new ProcessBuilder(cpars);
        // prepare string for logging
        StringBuffer co = new StringBuffer();
        for (String s : cpars) { co.append(s); co.append(' '); }
        RestLogger.info(co.toString());
        builder.redirectErrorStream(true);
        // collect the result
        List<String> output = new ArrayList<>();
        Process process = builder.start();
        StreamGobbler streamGobbler =
                new StreamGobbler(process.getInputStream(), s -> {
                    RestLogger.info(s);
                    output.add(s);
                });
        Executors.newSingleThreadExecutor().submit(streamGobbler);
        process.waitFor();
        int exitval = process.exitValue();
        RestLogger.info("Exit code " + exitval);
        return exitval;
    }
}
