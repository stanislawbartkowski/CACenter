package com.ca.restapi;

import org.junit.Test;

import java.io.IOException;

import static org.junit.Assert.*;

public class RunCaCommandTest {

    @Test
    public void test1() throws IOException, InterruptedException {

        int res = RunCaCommand.run("aaaa");
        System.out.println("res=" + res);
        assertEquals(4,res);

    }

    @Test
    public void test2() throws IOException, InterruptedException {

        int res = RunCaCommand.run("makecert","/C=PL/ST=Mazovia/L=Warsaw/O=MyHome/OU=MyRoom/CN=www.example.com");
        System.out.println("res=" + res);
    }

}