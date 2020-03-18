package com.ca.restapi;

import org.junit.Test;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;

public class RunRestTest extends RunRestHelper {


    @Test
    public void test1() throws IOException {
        HttpURLConnection conection = callRest("subcert?subject=aaaaaaaaaaaaa",null);
        int res = conection.getResponseCode();
        assert(res == 400);
    }

    // &#61;

    @Test
    public void test2() throws IOException {
        HttpURLConnection conection = callRest("subcert?subject=/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com",null);
        int res = conection.getResponseCode();
        assert(res == 200);
    }

    @Test
    public void test3() throws IOException {
        HttpURLConnection conection = callRest("csrcert?subject=/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com",null);
        int res = conection.getResponseCode();
        assert(res == 400);
    }

    @Test
    public void test4() throws IOException {
        String messdata="aaabbbbbcccccccccccccccffffffffffffffffffff";
        HttpURLConnection conection = callRest("csrcert",messdata.getBytes());
        int res = conection.getResponseCode();
        assert(res == 400);
    }

    private static final String CSR="/home/sbartkowski/work/CACenter/CARestApi/src/main/resources/www.example.com.csr.pem";

    @Test
    public void test5() throws IOException {
        File f = new File(CSR);
        byte[] b = Files.readAllBytes(f.toPath());
        HttpURLConnection conection = callRest("csrcert",b);
        int res = conection.getResponseCode();
        assert(res == 200);
    }

}