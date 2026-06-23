package com.student.controller;

import static com.student.config.AppConstants.GET_STUDENTS_URL;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.student.exceptions.AppException;
import com.student.model.Student;
import com.student.service.impl.StudentServiceImpl;

import lombok.extern.slf4j.Slf4j;

@RestController
@RequestMapping(GET_STUDENTS_URL)
@Slf4j
public class StudentController {

	@Autowired
	private StudentServiceImpl studentService;

	@GetMapping
	public ResponseEntity<List<Student>> getStudents() {
		List<Student> studentsList = null;
		try {
			studentsList = studentService.getStudents();
		} catch (Exception e) {
			throw new AppException(e);
		}
		return ResponseEntity.ok(studentsList);
	}

	@GetMapping("/health")
	public String imHealthy() {
		return "{healthy: true}";
	}
}
