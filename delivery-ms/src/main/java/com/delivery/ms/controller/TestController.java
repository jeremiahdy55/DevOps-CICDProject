package com.delivery.ms.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @RequestMapping("/test")
	public String testingMS() {
		return "delivery-ms is up and running!";
	}
    
}
