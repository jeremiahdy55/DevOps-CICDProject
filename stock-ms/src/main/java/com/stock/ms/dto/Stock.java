package com.stock.ms.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class Stock {

	private String item;

	private int quantity;

	public String getItem() {
		return item;
	}

	public void setItem(String item) {
		this.item = item;
	}

	public int getQuantity() {
		return quantity;
	}

	public void setQuantity(int quantity) {
		this.quantity = quantity;
	}
	
	

}
