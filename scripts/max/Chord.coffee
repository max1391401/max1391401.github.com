max.chord = do ->

    #PRIVATE PROPERTIES########################################################################################
    
    model = null

    diagramRotation = 0

    splines = []
        
    bundle = null
    line = null
    div = null
    svg = null
    
    #PRIVATE METHODS##########################################################################################
    ###Draw chord draws the diagram in the div. It uses D3.js to add and manipulate elements on the DOM
    
    often we want a certain part of the diagram to stay stationary, for example if a node is selected that node
    should stay in the same location, this is what the argument stationaryNode is for. 
    ###
    drawChord = (stationaryNode) ->
        
        nodes = model.getNodes()
        edges = model.getEdges()
        
        
        if stationaryNode?
            changeInAngle = 0
            for node in nodes
                if node.name is stationaryNode.name
                    changeInAngle = stationaryNode.x - node.x
                    if changeInAngle < 0
                        changeInAngle += 360                    
                    break
            if changeInAngle isnt 0 
                for node in nodes
                    node.x = (node.x + changeInAngle) % 360
        
            
        splines = bundle(edges)
        
        ###we removed everything then redraw it, this could be improved for efficency###
        svg.selectAll("path.edge")
                        .remove()                        
        svg.selectAll("g.node")
                        .remove()
        
        ###add all the path elecments (edges)
        
        the .selectAll("path.edge") works similar to a jQuery selector.
        .data(edges) loops over each item in edges
        .enter() appends the item if it doesn't exist yet, this is kinda where because we 'selected' with .selectALL
      
        ###
        path = svg.selectAll("path.edge")
                        .data(edges) #for each data enter
                            .enter().append("svg:path")
                                .attr("class", (d) -> 
                                    "edge 
                                    source-#{d.source.name.split('@@').pop().split('$').join('\\$')} 
                                    target-#{d.target.name.split('@@').pop().split('$').join('\\$')} 
                                    #{if d.selected then 'selected' else ''}
                                    ")
                                .attr("d", (d, i) ->    line(splines[i]))
                                .on("mousedown", mouseDownEdge)
                             
        
        ###add all the nodes, or names
        works similar to adding all the edges,
        
        this doesn't add the text, just adds the svg g container and rotates is around the circle to 
        the right place, this is what transform rotate and translate does
                
        also attaches the mouse events
       ###
        labels = svg.selectAll("g.node")
            .data(nodes.filter((n) -> 
                return not n.expanded
                ))
            .enter().append("svg:g")
                .attr("class", (d) -> "node " + d.type + if d.selected then " selected" else "")
                .attr("id", (d) -> 
                            d.id = "node-" + d.name.split('@@').pop().replace('$', '$')
                            return d.id)
                .attr("transform", (d) -> "rotate(#{(d.x - 90)%360})translate(#{d.y})")
                .on("mouseover", mouseover)
                .on("mouseout", mouseout)
        
        arrowWidth = 30
        
        ###put the text labels in each node###
        labels.append("svg:text")
                .attr("dx", (d) -> 
                    if d.x < 180 
                        if d.collapsible
                            6+arrowWidth 
                        else 
                            6
                    else 
                        if d.collapsible
                            -6-arrowWidth
                        else
                            -6
                    )
                .attr("dy", ".31em")
                .attr("text-anchor", (d) -> (if d.x < 180 then "start" else "end"))
                .attr("transform", (d) -> (if d.x < 180 then null else "rotate(180)"))
                .text (d) -> 
                    if d.type is 'package'
                        filterPackageName(d.name.split('@@').pop())
                    else
                        d.name.split('@@').pop()
                    
                .on("mousedown", mouseDownNode)
       
        ###attach the expand and collapse images, the .filter allows us to only do it if its needed###
        labels.filter( (d) -> d.collapsible )
            .append("svg:image")
                .attr("x", "-1")
                .attr("y", "-10")
                .attr("width", arrowWidth)
                .attr("height", "20")
                .attr("xlink:href", "images/collapse.png")
                .on("mousedown", (node) -> 
                        console.time 'collapseNode Execution'
                        model.collapseNode(node)
                        stationaryNode =
                            name : node.parent.name
                            x : node.x
                        drawChord(stationaryNode)
                        console.timeEnd 'collapseNode Execution'
                        return )

        labels.filter( (d) -> d.expandable )
            .append("svg:image")
                .attr("x", (d) ->
                        x = $("##{d.id.split('.').join('\\.')} text").width() + 10
                        if d.collapsible
                            x = x + arrowWidth #add a bit of space for the the collapse icon                        
                        return x)
                .attr("y", "-10")
                .attr("width", "20")
                .attr("height", "20")
                .attr("xlink:href", "images/expand.png")
                .on("mousedown", (node) -> 
                        console.time 'expandNode Execution'
                        model.expandNode(node)                        
                        stationaryNode =
                            name : node.name
                            x : node.x
                        drawChord(stationaryNode)
                        console.timeEnd 'expandNode Execution'
                        return )
               
#        d3.select("input[type=range]").on "change", ->
#            line.tension (100-@value) / 100
#            path.attr "d", (d, i) -> line splines[i]

        updateBreadCrumbs()
        
        return    
    
    
    
    #mousover highlighting stuff
    mouseover = (d) ->
        nameArray = d.name.split('@@')
        
        names = "<b id='breadcrumbseperator'></b>" + max.dataset #emptpy bold to keep the text height the same with or without the large seperators
        
        if nameArray[0]?
            names += " <b id='breadcrumbseperator'>&gt;</b> #{nameArray[0]}"
        if nameArray[1]? #its a package
            names += " <b id='breadcrumbseperator'>&gt;</b> #{nameArray[1]}"
        if nameArray[2]? #its a class
            names += " <b id='breadcrumbseperator'>&gt;</b> #{nameArray[2]}"
        $("#hoverBreadCrumbs").html(names)     
        
        
        #why so many \\\\\\\?
        #to start with each \ is escaped by javascript
        #so actually we're replacing $ with \\\$
        #why '\\\$' == '\\'+'\$', which results in \$ when it is escaped when searching
        #maddness
        nodeName = nameArray.pop() #last thing
        nodeName = nodeName.split('$').join('\\\\\\$')
        nodeName = nodeName.split('.').join('\\.')
        svg.selectAll("path.edge.target-" + nodeName).classed("target", true).each updateNodes("source", true)
        svg.selectAll("path.edge.source-" + nodeName).classed("source", true).each updateNodes("target", true)
        return
    mouseout = (d) ->
        $("#hoverBreadCrumbs").html('') 
        nodeName = d.name.split('@@').pop()
        nodeName = nodeName.split('$').join('\\\\\\$')
        nodeName = nodeName.split('.').join('\\.')
        svg.selectAll("path.edge.source-" + nodeName).classed("source", false).each updateNodes("target", false)
        svg.selectAll("path.edge.target-" + nodeName).classed("target", false).each updateNodes("source", false)
        return


    updateNodes = (name, value) ->
        (d) ->
            @parentNode.appendChild this    if value
            svg.select("#node-" + (d[name].name.split('@@').pop().split('$').join('\\\\\\$')).split('.').join('\\.')).classed name, value


    mouseDownNode = (node) ->
        console.time 'mouseDownNode Execution'
        e = d3.event
                
        if e.which == 1 #left click
            if e.ctrlKey 
                model.toggleNodeSelection(node) 
            else 
                model.toggleNodeSelection(node, true) #true is reset first
            
            stationaryNode =
                name : node.name
                x : node.x
            
            drawChord(stationaryNode)
        updateBreadCrumbs()
        console.timeEnd 'mouseDownNode Execution'
        return false
        
    mouseDownEdge = (edge) ->
        e = d3.event
        #alert "strenght:#{edge.strength}  type:#{edge.type}"
        if e.which == 1 #left click
            if e.ctrlKey 
                model.toggleEdgeSelection(edge) 
            else
                model.toggleEdgeSelection(edge, true) #true is reset first
            drawChord()
        
            
    updateBreadCrumbs = () ->
        selectedNodes = max.selection.getSelectedNodes()
        selectedEdges = max.selection.getSelectedEdges()
        
        #selected edges just have a node at each end. We just want to treat
        #this as if the two nodes were selected
        for edge of selectedEdges
            split = edge.split(" ")
            node1 = split[0]
            node2 = split[2]
            selectedNodes[node1] = true
            selectedNodes[node2] = true
        
        selectionTree = {}
        for node of selectedNodes
            splitName = node.split("@@")
            if not selectionTree[splitName[0]]?
                selectionTree[splitName[0]] = {}
                
            if splitName.length > 1 #its a package or class thats selected
                if not selectionTree[splitName[0]][splitName[1]]?
                    selectionTree[splitName[0]][splitName[1]] = {}
                
            if splitName.length > 2 #its a class
                if not selectionTree[splitName[0]][splitName[1]][splitName[2]]?
                    selectionTree[splitName[0]][splitName[1]][splitName[2]] = {}
                
            
        #http://jsfiddle.net/7TKtx/
        #http://jsfiddle.net/7TKtx/15/
        #http://jsfiddle.net/7TKtx/20/
        
   
      
        $("#breadCrumbs").html('') 

        $("#breadCrumbs").append("<span class='bcSpan' id='bc#{max.dataset}' onclick='max.chord.selectSingleNode()'  >#{max.dataset}</span>")
        
        
        #jquery selectors can not have . in them, need to escape them with \\
        
        datasetWidth = $("#bc" + max.dataset.split('.').join('\\.')).width() #+ 10 # +10 because of page margin or something. 
        
        for jar, packages of selectionTree

            breakAppended = false

            $("#breadCrumbs").append("<span class='bcSpan' id='bc#{jar}' onclick='max.chord.selectSingleNode(\"#{jar}\")' style='left:#{datasetWidth}px'>&nbsp;&gt;&nbsp;#{jar}</span>")

            jarWidth = $("#bc#{jar.split('.').join('\\.')}").width()

            for packag, classes of packages 
                $("#breadCrumbs").append("<span class='bcSpan' id='bc#{packag}' onclick='max.chord.selectSingleNode(\"#{jar}@@#{packag}\")' style='left:#{datasetWidth+jarWidth}px' >&nbsp;&gt;&nbsp;#{packag}</span>")

                packageWidth = $("#bc" + packag.split('.').join('\\.')).width()
                
                breakAppended = false
                

                for clas of classes

                    $("#breadCrumbs").append("<span class='bcSpan' id='bc#{clas}' onclick='max.chord.selectSingleNode(\"#{jar}@@#{packag}@@#{clas}\")' style='left:#{datasetWidth+jarWidth+packageWidth}px;Font-Weight:Bold' >&nbsp;&gt;&nbsp;#{clas }</span>")
                    $("#breadCrumbs").append("<br>")
                    breakAppended = true

                if not breakAppended
                    $("#breadCrumbs").append("<br>")
                    $("#bc" + packag.split('.').join('\\.')).css({'font-weight':'bold'})
                    breakAppended = true


            if not breakAppended 
                $("#breadCrumbs").append("<br>")
                $("#bc#{jar.replace('.','\\.')}").css({'font-weight':'bold'})
        
        $("#breadCrumbs").css("z-index","50");
    
    packageNameMap = {}
    
    getShortName = (name) ->
        
        if packageNameMap[name]?
            return packageNameMap[name]
        else
            nameArray = name.split('.')
            lastItem = nameArray[nameArray.length-1] 

            for i in [0 ... lastItem.length]

                newName = '$'

                for item in nameArray
                    if item isnt lastItem #if its not the last one, just add the first char
                        newName += item.charAt(0)
                    else
                        newName += item.substring(0, i+1)

                if not inObject(newName, packageNameMap)
                    packageNameMap[name] = newName
                    return newName
                
            return false
    
    inObject = (valueToCheck, object) ->
        for key, value of object
            if valueToCheck is value
                return true
        return false
    
    filterPackageName = (packageName) ->
        # THIS IS THE FILTER ORDER
        filterOrder = 2 # get this properly. 
        
        console.log packageName
        
        while (filterOrder isnt 0)
            postitionOfNthPeriod = packageName.indexOf "." #this is where we will split the string
            n = filterOrder
            while (n-- > 0 and postitionOfNthPeriod != -1)
                postitionOfNthPeriod = packageName.indexOf(".", postitionOfNthPeriod + 1)

            firstBit = packageName.substring(0, postitionOfNthPeriod)
            lastBit = packageName.substring(postitionOfNthPeriod+1, packageName.length)
            
            firstBit = getShortName(firstBit)
            
            if firstBit 
                return "#{firstBit}.#{lastBit}"
            else #getShortName returned false
                filterOrder--
#                debugger
            
        return packageName #if you cant find a new name, just return false
        
        
       
    
    
    
    #PUBLIC METHODS############################################################################################
    setModel : (m) ->
        model = m
        
        bundle = d3.layout.bundle()

        line = d3.svg.line.radial()#create a new radial line generator
            .interpolate("bundle")
            .tension(.85)
            .radius( (d) ->    d.y )
            .angle( (d) -> (d.x) / 180 * Math.PI )

        div = d3.select("#chordDiv")

        svg = div.append("svg:svg") #svg is a reference pointing to the SVG object
            .attr("width", max.diagramWidth)
            .attr("height", max.diagramHeight)
            .append("svg:g")
            .attr("transform", "translate(#{max.diagramWidth/2},#{max.diagramHeight/2})")

     drawChord : () ->
        drawChord()
     
     #this is called when a breadcrumb is clicked
     #no nodeName means the root was clicked - just reset the diagram
     #nodeName is full name, eg jar@@package@@class
     selectSingleNode : (nodeName) ->
        if nodeName?
            model.selectSingleNode(nodeName)
        else 
            model.resetSelections()
            
        drawChord()
        
        updateBreadCrumbs()

