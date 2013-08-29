var $ = function(o){return document.getElementById(o)};
var w = function(s){return document.write(s)};

function c(str, operation, key){
	key = key ? key : getCookie('key');
    var s = str.split("");
    var k = key.split("");
    var j = 0;
    var list = [];
    for(var i = 0; i < s.length; i ++){
        j = j == k.length - 1 ? 0 : j + 1;
        list.push(String.fromCharCode(operation=='ENCODE' ? s[i].charCodeAt(0) + k[j].charCodeAt(0) : s[i].charCodeAt(0) - k[j].charCodeAt(0)));
    }
    return list.join('');
}

function getCookie(key){
	var arrCookie = document.cookie.split('; ');
	for(var i=0; i<arrCookie.length; i++){
		var arr = arrCookie[i].split('=');
		if(arr[0] == key){
			return arr[1];
		}
	}
	return null;
}


var xmlHttp;
function createXMLHttp(){
	if(window.ActiveXObject){
		xmlHttp = new ActiveXObject("Microsoft.XMLHTTP");
	}else if(window.XMLHttpRequest){
		xmlHttp = new XMLHttpRequest();
	}
}
function ajax(put,out){
	if($('secinput').value != ''){
		$(out).innerHTML = "<img src='/static/img/loading.gif' align='absmiddle' border='0'>&nbsp;Loading...";
		createXMLHttp();
		xmlHttp.onreadystatechange = function(){dodo(out)};
		xmlHttp.open("get",put,true);
		xmlHttp.send(null);
	}
}
function dodo(out){
	if(xmlHttp.readyState==4){
		if(xmlHttp.status==200){
			$(out).innerHTML=xmlHttp.responseText;
		}
	}
}

function newpost(){
	$('title1').focus();
	scrollBy(0, document.body.scrollHeight);
}

function reply(floor){
	$('content1').focus();
	if(floor==0){
		txt = '';
	}else{
		txt = '回复：' + floor + '楼\n';
	}
	$('content1').value = txt;
	scrollBy(0, document.body.scrollHeight);
}