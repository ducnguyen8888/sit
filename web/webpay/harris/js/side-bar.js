	$("#menu-toggle").click(function(e) {
		e.preventDefault();
		$("#wrapper").toggleClass("toggled");
		});
	$("#menu-toggle-2").click(function(e) {
		e.preventDefault();
		$("#wrapper").toggleClass("toggled-2");
		if ( $("#wrapper").hasClass("toggled-2") ) 
			setTimeout(function() { $('#menu ul').hide(); },500);
		});

	function initMenu() {
		$('#menu ul').hide();
		$('#menu ul').children('.current').parent().show();
		//$('#menu ul:first').show();
		$('#menu li a').click(
				function() {
					var checkElement = $(this).next();
					if((checkElement.is('ul')) && (checkElement.is(':visible'))) {
						$('#menu ul:visible').slideUp('normal');
						return false;
					}
					if((checkElement.is('ul')) && (!checkElement.is(':visible'))) {
						$('#menu ul:visible').slideUp('normal');
						checkElement.slideDown('normal');
						return false;
					}
				}
			);
	}

	$(document).ready(function() { initMenu(); });