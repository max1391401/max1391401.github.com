#initalise the max object which is used as the namespace for the project
max = {}



max.diagramWidth = $(document).width()
max.diagramHeight = $(document).height() - 20
max.diagramTextSpace = 200
### this should come from somewhere more dynamic, should also be encoded within the URL and bbq stuff ###
max.dataset = "tomcat-7.0.2"
#max.dataset = "nekohtml-1.9.14.jar"
#max.dataset = "jre1.7.0"

$("#chordDiv").css("width", max.diagramWidth+"px")
$("#chordDiv").css("height", max.diagramHeight+"px")

$(window).resize () ->
    max.diagramWidth = $(window).width()
    max.diagramHeight = $(window).height()
    #not working yet, need to change some values in the chord
    max.chord.drawChord()
    

#bind url change events to state.applyState()
$(window).bind "hashchange", (e) ->
    max.state.applyState()
    
$(window).bind "load", (e) ->
    ### This could be changed to get it from xplarc ###
    d3.json "./data/#{max.dataset}.json", (jsondata) ->

        console.time 'Init timer'
        max.model.setJSON(jsondata)
        max.chord.setModel(max.model)
        
        max.state.initState()
        
        $("#loadingMessage").remove()
        
        max.chord.drawChord()
        
        console.timeEnd 'Init timer'
           
    
    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
#     max.state.onStateChanged "expandedNodes", (property, oldValue, newValue) ->   
#        model.expandedNodes = newValue
#        drawChord(model.nodes, model.links)