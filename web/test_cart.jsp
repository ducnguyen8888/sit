<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"%><jsp:useBean  id="ds" class="act.sit.Dealerships"  scope="session"/><jsp:useBean  id="payments" class="act.sit.Payments"  scope="session"/><%
  out.print(payments.getPayments(ds))   ;
%>