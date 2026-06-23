package com.student.exceptions;

public class AppException extends RuntimeException {

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	public AppException(String message, Throwable e) {
		super(message, e);
	}

	public AppException(Throwable e) {
		super(e);
	}

	public AppException(String message) {
		super(message);
	}
}
