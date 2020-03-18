package com.ca.restapi;

import com.rest.restservice.RestLogger;
import com.rest.restservice.RestStart;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;

public class CARestApi extends RestStart {

    private static void P(String s) {
        System.out.println(s);
    }

    private static final String STOREKEY = "store.key.filename";
    private static final String STOREPASSWORD = "key.store.password";
    private static final String ALIAS = "alias";

    private static void help() {
        P(" Non-secure HTTP connection:");
        P("   Parameters: /port number/ /ca.sh path/");
        P("     Example");
        P("       java ...  9800 /home/sbartkowski/work/CACenter/ca.sh");
        P("");
        System.exit(4);
    }

    private static String getParam(Properties prop, String key) throws IOException {
        String res = prop.getProperty(key);
        if (res == null || "".equals(res)) {
            String mess = "Parameter " + key + " not found in the secure property file";
            RestLogger.L.severe(mess);
            throw new IOException(mess);
        }
        return res;
    }


    public static void main(String[] args) throws IOException {
        if (args.length != 2) {
            help();
        }
        int PORT = Integer.parseInt(args[0]);
        String capath = args[1];
        RestLogger.info(capath);
        RunCaCommand.setCA(capath);
        RestStart(PORT, (server) -> new RestServices().registerServices(server), new String[]{});
    }
}
