var max;

max = {};

max.diagramWidth = $(document).width();

max.diagramHeight = $(document).height() - 20;

max.diagramTextSpace = 200;

/* this should come from somewhere more dynamic, should also be encoded within the URL and bbq stuff
*/


max.dataset = "tomcat-7.0.2";

$("#chordDiv").css("width", max.diagramWidth + "px");

$("#chordDiv").css("height", max.diagramHeight + "px");

$(window).resize(function() {
  max.diagramWidth = $(window).width();
  max.diagramHeight = $(window).height();
  return max.chord.drawChord();
});

$(window).bind("hashchange", function(e) {
  return max.state.applyState();
});

$(window).bind("load", function(e) {
  /* This could be changed to get it from xplarc
  */
  return d3.json("./data/" + max.dataset + ".json", function(jsondata) {
    console.time('Init timer');
    max.model.setJSON(jsondata);
    max.chord.setModel(max.model);
    max.state.initState();
    $("#loadingMessage").remove();
    max.chord.drawChord();
    return console.timeEnd('Init timer');
  });
});
