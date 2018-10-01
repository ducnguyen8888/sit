<%@ page language="java" contentType="text/html; charset=ISO-8859-1" pageEncoding="ISO-8859-1"
%><%
session.invalidate();
%><!doctype html>
<html lang="en-us">
<head>
    <title>SIT Logout</title>
    <style>
        html {  font-size: 24px; font-style: italic; }
        .centered { position: fixed; top: 30%; left: 50%; transform: translate(-50%, -50%); }
    </style>
</head>
<body>
<div class="centered">You are now logged out...</div>
<jsp:forward page="login.jsp" />
</body>
</html>
