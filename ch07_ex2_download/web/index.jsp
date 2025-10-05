<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Murach's Java Servlets and JSP</title>
    <link rel="stylesheet" href="styles/main.css" type="text/css"/>
</head>
<body>

<h1>List of albums</h1>

<p>
    <c:forEach var="p" items="${products}">
        <a href="download?action=checkUser&amp;productCode=${p.code}">
            ${p.title}
        </a><br>
    </c:forEach>
</p>

</body>
</html>
