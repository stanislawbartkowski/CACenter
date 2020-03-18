package com.ca.restapi;

import com.rest.restservice.PARAMTYPE;
import com.rest.restservice.RestHelper;
import com.rest.restservice.RestLogger;
import com.rest.restservice.RestParams;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import javax.swing.text.html.Option;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

class RestServices {


    private abstract class ServiceHelper extends RestHelper.RestServiceHelper {

        ServiceHelper(String url) {
            super(url, false);
        }

        public RestParams getParam(HttpExchange httpExchange,boolean requestdata) throws IOException {
            List<String> methods = new ArrayList<String>();
            methods.add(RestHelper.POST);
            return new RestParams(RestHelper.POST, Optional.of(RestParams.CONTENT.ZIP), false, methods, Optional.empty(),requestdata);
        }
    }

    class GenCert extends ServiceHelper {

        private static final String SUBJECT = "subject";

        GenCert() {
            super("subcert");
        }

        @Override
        public RestParams getParams(HttpExchange httpExchange) throws IOException {
            RestParams par = getParam(httpExchange,false);
            par.addParam(SUBJECT, PARAMTYPE.STRING);
            return par;
        }

        @Override
        public void servicehandle(RestHelper.IQueryInterface v) throws IOException, InterruptedException {
            String subject = getStringParam(v, SUBJECT);
            File tempfile = File.createTempFile("ttt", null);
            tempfile.deleteOnExit();
            int res = RunCaCommand.run("makecert", subject, tempfile.getAbsolutePath());
            if (res != 0) {
                String message = "Error while generating the certficate.";
                RestLogger.L.severe(message);
                produceResponse(v, Optional.of(message), RestHelper.HTTPBADREQUEST);
            } else {
                byte[] zip = Files.readAllBytes(tempfile.toPath());
                produceByteResponse(v, Optional.of(zip), RestHelper.HTTPOK, Optional.empty());
            }
            tempfile.delete();
        }
    }

    class GenCertCSR extends ServiceHelper {

        GenCertCSR() {
            super("csrcert");
        }

        @Override
        public RestParams getParams(HttpExchange httpExchange) throws IOException {
            return getParam(httpExchange,true);
        }

        @Override
        public void servicehandle(RestHelper.IQueryInterface v) throws IOException, InterruptedException {
            File tempfile = File.createTempFile("ttt", null);
            File tempcsr = File.createTempFile("ttt", null);
            tempfile.deleteOnExit();
            tempcsr.deleteOnExit();
            // write binary csr file to temporary
            try (FileOutputStream fos = new FileOutputStream(tempcsr)) {
                fos.write(v.getRequestData().array());
            }
            int res = RunCaCommand.run("csrcert", tempcsr.getAbsolutePath(), tempfile.getAbsolutePath());
            if (res != 0) {
                String message = "Error while generating the certficate.";
                RestLogger.L.severe(message);
                produceResponse(v, Optional.of(message), RestHelper.HTTPBADREQUEST);
            } else {
                byte[] zip = Files.readAllBytes(tempfile.toPath());
                produceByteResponse(v, Optional.of(zip), RestHelper.HTTPOK, Optional.empty());
            }
            tempfile.delete();
            tempcsr.delete();
        }
    }


    void registerServices(HttpServer server) {
        RestHelper.registerService(server, new GenCert());
        RestHelper.registerService(server, new GenCertCSR());
    }

}

