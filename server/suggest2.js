// APEX Suggest2 functions
// Author: Matan Poran
// Version: 1.0.0

var mporan_suggest2 = {

	loadSuggestions: function () {
		var daThisAjaxIdentifier = this.action.ajaxIdentifier;
		var finishedFetch = false;
		var htmlInner;
		var daThis = this;
		var affectedElementId = daThis.action.attribute01;
		var suggestContainerDivId = "suggest-" + affectedElementId;
		var affectedElementSelector = "#" + affectedElementId;
		var suggestionsTitle = daThis.action.attribute02;
		var hasLov = Boolean(daThis.action.attribute03 == 'Y'); 
		var displayRemove = Boolean(daThis.action.attribute05 == 'Y');
		var rapidSelection = Boolean(daThis.action.attribute08 == 'Y');
		var faIcon = daThis.action.attribute09;
		var customHtml = daThis.action.attribute10;
		var select2Instance = $(affectedElementSelector).data('select2');

		apex.debug("affectedElementSelectorId " + affectedElementId);

		select2Instance.on('results:message', function(e){
			mporan_suggest2.fixGap(select2Instance);
		}
		);

		$("body").on('select2:open', affectedElementSelector, function (e) {
			apex.debug("select2:open");

			if (!$("#" + suggestContainerDivId).length) {

				if(customHtml !== null) {
					customHtml = '<div class="suggest__custom-html">' + customHtml + '</div>';
				} else {
					customHtml = '';
				}

				var htmlContainer = '<div class="suggest__menu" id="' + suggestContainerDivId + '">' 
				+ customHtml
				+ '<div class="suggest__options"></div>'
				+ '</div>';

				$("#select2-" + affectedElementId + "-results").parents(".select2-dropdown").append(htmlContainer);
			}
			if (finishedFetch) {
				mporan_suggest2.displayResult(suggestContainerDivId, htmlInner);
			} else {
				if (!$(".suggest__loading").length && hasLov) {
					$("#" + suggestContainerDivId).append('<div class="suggest__header suggest__loading">Loading suggestions...</div>');
				}
			}
			$("#" + suggestContainerDivId).show();
			$(".suggest__option--selected i").show();
			$(".suggest__option").removeClass("suggest__option--selected");

			function toggleMenuKeyup() {
				apex.debug("toggleMenuKeyup");
				if ($(this).val().length > 0 && $(".suggest__menu").is(":visible")) {
					$(".suggest__menu").hide(); 
				}
				if ($(this).val().length == 0) {
					$(".suggest__menu").show();
				}
				mporan_suggest2.fixGap(select2Instance);
			};
			
			$('.select2-container')
				.off('keyup', '.select2-search__field')
				.on('keyup', '.select2-search__field', toggleMenuKeyup);

		}); //select2:open
	
		if (hasLov) {
			apex.server.plugin(
				daThisAjaxIdentifier, {
				x01: 'DRAW'
			}, {
				dataType: "json",
				success: function (listOfItems) {

					finishedFetch = true;
					apex.debug("finishedFetch " + finishedFetch + "  " + suggestContainerDivId + "  " + listOfItems);

					if (listOfItems.length > 0) {

						htmlInner = '<div class="suggest__header">' + suggestionsTitle;
						if (displayRemove) {
							htmlInner += '<i>Remove All</i>';
						};
						htmlInner += '</div>'; //suggest__header

						// Items

						var faIconSpan = '';
						if (faIcon) {
							faIconSpan = '<span class="fa ' + faIcon + '" aria-hidden="true"></span>'
						}

						for (var arrayIndex in listOfItems) {
							htmlInner += '<a href="javascript:void(0);" class="suggest__option " data-id="' +
								listOfItems[arrayIndex][1] + '">' + faIconSpan +
								listOfItems[arrayIndex][0];
							if (displayRemove) {
								htmlInner += '<i>Remove</i>'
							}
							htmlInner += '</a>';
						}

						htmlInner += '</div>'; //suggest__menu

						// Click
						$("body").on("click", "#" + suggestContainerDivId + " .suggest__option", function () {
							event.preventDefault();
							var thisClone = $(this).clone();
							thisClone.find("i").remove();
							var thisText = thisClone.text();
							var thisId = $(this).data("id");
							$(affectedElementSelector + " option").each(function(){ 
								if($(this).val() == thisId){
									$(this).remove();
									apex.debug('Removed existing option');
								}
							})
							var option = new Option(thisText, thisId);
							option.selected = true;
							$(affectedElementSelector).append(option); 
							$(affectedElementSelector).trigger("change");

							if (rapidSelection) {
								$(this).addClass("suggest__option--selected");
								$(this).children("i").hide();
							} else {
								$(affectedElementSelector).select2("close");
							}
						});

						if (displayRemove) {
							mporan_suggest2.deleteItem(affectedElementId, daThisAjaxIdentifier);
						}

					} //if (listOfItems.length > 0)

					if ($("#" + suggestContainerDivId).length > 0) {
						mporan_suggest2.displayResult(suggestContainerDivId, htmlInner);
					}
				} // success
			}); // apex.server.plugin
		} //if (hasLov)	
		}, // loadSuggestions
	fixGap: function(select2Instance) {
			apex.debug("fixGap"); 
			// fix gap between dropdown and item when dropdown opens above				
			select2Instance.dropdown._resizeDropdown(); 
			select2Instance.dropdown._positionDropdown();
		},
	displayResult: function (suggestContainerDivId, htmlInner) {
		
		if (!$("#" + suggestContainerDivId + " .suggest__option").length) { // Append only once
			if (htmlInner) { // Has suggestions
				apex.debug("appending");
				$(".suggest__loading").remove();
				//$(".suggest__options").addClass("suggest__options--populated");
				$("#" + suggestContainerDivId + " .suggest__options").append(htmlInner);
			} else {
				$("#" + suggestContainerDivId + " .suggest__options").remove();
			}
		}		
	},

	deleteItem: function (affectedElementId, daThisAjaxIdentifier) {
		apex.debug("function deleteItem " + suggestContainerDivId);
		
		var suggestContainerDivId = "suggest-" + affectedElementId;
		var select2Instance = $("#" + affectedElementId).data('select2');

		// DELETE

		$("body").on("click", "#" + suggestContainerDivId + " .suggest__option i", function (event) {
			event.stopPropagation();
			var itemToDelete = $(this).parent().data("id");
			apex.debug("deleteItem " + itemToDelete);
			apex.server.plugin(
				daThisAjaxIdentifier, {
				x01: 'DELETE',
				x02: itemToDelete
			}, {
				dataType: "text",
				success: function (pData) {
						apex.debug("Deleted Single");
				}
			}
			);
			$(this).parent().remove();
			if ($("#" + suggestContainerDivId + " .suggest__option").length == 0) {				
				$(".suggest__options").hide();

			};
			mporan_suggest2.fixGap(select2Instance);
		}); //on click


		// DELETE_ALL

		$("body").on("click", "#" + suggestContainerDivId + " .suggest__header i", function (event) {
			event.stopPropagation();
			apex.debug("Delete All");
			apex.server.plugin(
				daThisAjaxIdentifier, {
				x01: 'DELETE_ALL'
			}, {
				dataType: "text",
				success: function (pData) {
					apex.debug("Deleted All");
				}
			}
			);
			$(".suggest__options").hide();
			mporan_suggest2.fixGap(select2Instance);


		}); //on click		

	},
}