$(document).ready(function(){

	// HatenaBookmark
//	setTimeout(function(){
		getHBData(0);
//	}, 300);

	// SlideShare
	setTimeout(function(){
		getSSData(0);
	}, 500);

}); // end of ready()


var hbof;
function getHBData(of) {

	hbof = of; // page number
	if (hbof < 0) {
		hbof = 0;
	}

	$.getJSON('./api.cgi', {section:'hb',of:hbof}, function(json){
		$('#hb>.loading').css('display','none');
		$.each(json, function(key, val){
			var text = '<li>'
			         + '<img src="'+val.favicon+'" width="16" height="16"'
			         + ' class="favicon" alt="favicon">'
			         + '<div class="s">'
			         + '<a href="'+val.url+'"'
			         + ' title="'+val.description+'" target="_blank">'
			         +   val.title
			         + '</a><br>'
			         + '<a href="http://b.hatena.ne.jp/entry/'+val.url+'"'
			         + ' class="usercount" target="_blank">'
			         +   val.usercount+' users'
			         + '</a>'
			         + ' '
			         + '<span class="datetime">'+val.datetime+'</span>'
			         + '</div>'
			         + '</li>';
			$('#hb>ul').append(text);
		});
		$('#hb>ul').before(
			$('<p/>').addClass('page')
			.append(
				$('<a/>').addClass('future')
				.attr('title','最近の5件に進む')
				.click(function(){
					$('#hb>.page').remove();
					$('#hb>ul').empty();
					$('#hb>.loading').css('display','block');
					getHBData(hbof-1);
				})
				.html('&#171;') // '<<'
			).append(
				$('<a/>').addClass('past')
				.attr('title','過去の5件に戻る')
				.click(function(){
					$('#hb>.page').remove();
					$('#hb>ul').empty();
					$('#hb>.loading').css('display','block');
					getHBData(hbof+1);
				})
				.html('&#187;') // '>>'
			)
		);
	});
}

var ssof;
function getSSData(of) {

	ssof = of; // page number
	if (ssof < 0) {
		ssof = 0;
	}

	$.getJSON('./api.cgi', {section:'ss',of:ssof}, function(json){
		$('#ss>.loading').css('display','none');
		$.each(json, function(key, val){
			var text = '<li>'
			         + '<a href="'+val.url+'"'
			         + ' title="'+val.description+'" target="_blank">'
			         +   val.title
			         + '</a><br>'
			         + '<span class="datetime">'+val.datetime+'</span>'
			         + '</li>';
			$('#ss>ul').append(text);
		});
		$('#ss>ul').before(
			$('<p/>').addClass('page')
			.append(
				$('<a/>').addClass('future')
				.attr('title','最近の5件に進む')
				.click(function(){
					$('#ss>.page').remove();
					$('#ss>ul').empty();
					$('#ss>.loading').css('display','block');
					getSSData(ssof-1);
				})
				.html('&#171;') // '<<'
			).append(
				$('<a/>').addClass('past')
				.attr('title','過去の5件に戻る')
				.click(function(){
					$('#ss>.page').remove();
					$('#ss>ul').empty();
					$('#ss>.loading').css('display','block');
					getSSData(ssof+1);
				})
				.html('&#187;') // '>>'
			)
		);
	});
}

