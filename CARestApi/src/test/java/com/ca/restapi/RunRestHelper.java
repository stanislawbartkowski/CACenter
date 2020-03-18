package com.ca.restapi;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.ProtocolException;
import java.net.URL;

abstract class RunRestHelper {

    protected HttpURLConnection callRest(String url, byte[] b) throws IOException {
        URL urlForGetRequest = new URL("http://localhost:9080/" + url);
        String readLine = null;
        HttpURLConnection conection = (HttpURLConnection) urlForGetRequest.openConnection();
        conection.setRequestMethod("POST");
        if (b != null) {
            conection.setDoOutput(true);
            OutputStream o = conection.getOutputStream();
            o.write(b);
            o.close();
        }
        int responseCode = conection.getResponseCode();
        System.out.println("resp=" + responseCode);
        if (responseCode != 200) {
            String mess = conection.getResponseMessage();
            System.out.println(mess);
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(conection.getErrorStream()))) {
                String line = null;
                while ((line = reader.readLine()) != null) {
                    System.out.println(line);
                }
            }
        }
        return conection;
    }

}
