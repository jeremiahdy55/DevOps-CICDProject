package com.order.ms.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TestController {

    @RequestMapping("/test")
	public String testingMS() {
		return "order-ms is up and running!";
	}
    
}
