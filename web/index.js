
function direc(){
  $.ajax({
    url: "./codigos",
    error: function(XMLHttpRequest, textStatus, errorThrown) {
        alert("El sistema debe ser cargado desde un esquema de protocolo: http, data, chrome, chrome-extension, chrome-untrusted, https. Creado usando comando de linea http-server de npm.");
    }
  }).then(function(html) {
    $(html).find('a[href$=html]').each(function() {
        $(".directorios").append("<button onclick='documento(this)'>" + $(this).text() + "</button>");
    });
    $(".directorios").append("<br><br><br>");
  });
}

function documento(e){
  $(".content").load("codigos/" + e.textContent, function(){
    $('.header').html("Jonathan Josafat - A01734225&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;Dir: " + document.getElementsByTagName("file")[0].getAttribute("ubicacion") + "&nbsp;&nbsp;-&nbsp;&nbsp;&nbsp;File: " + document.getElementsByTagName("file")[0].getAttribute("name") + "&nbsp;&nbsp;-&nbsp;&nbsp;Linea: · ");
  });
}

function control(){
  direc();
}
