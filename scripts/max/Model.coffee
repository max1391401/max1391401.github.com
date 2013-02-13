max.model = do ->
    
    #PRIVATE PROPERTIES########################################################################################
    nodes = null
    edges = null
    
    rawJSON = {}
    
    #these three are populated by generateNodeTree
    nodeTree = {} # a tree with nodename as key, and then an array of children
    nodeJars = {} #map with nodename as key, jar as value
    
    selectedEdgeEnds = {}
        
    nodesToBeIncluded = {}
    
    cluster = d3.layout.cluster()
        .size [ 360, (max.diagramHeight/2) - max.diagramTextSpace ]
        .sort (a, b) ->
            d3.ascending a.name, b.name
    
    #PRIVATE METHODS##########################################################################################
    
            
    ###this method populates three things, 
    Primarly the nodeTree,
    secondly the nodeJars, which maps key=[node.package+node.name] to node.jar
    third counts the number of jars 
   ###
    generateNodeTree = () ->
        
        #this is a map used only here to allow us to use the packageName.className
        #and get the actual class object from it
        edgeNameToNodeObject = {}
        
        console.time("generateNodeTree rawJson.nodes")
        
        nodeTree.root =
            name : "root"
            children : []
        
        for node in rawJSON.nodes
        
            jarName = node.container
            packageName = jarName + "@@" + node.namespace
            className = packageName + "@@" + node.name
            
            if not nodeTree[jarName]?
                nodeTree[jarName] = 
                    name : jarName
                    type : "jar"
                    #parent : nodeTree["root"]
                    children : []
                    edgesOut : {}
                    edgesIn : {}
                
                nodeTree.root.children.push nodeTree[jarName]    
                
                
            if not nodeTree[packageName]?
                nodeTree[packageName] = 
                    name : packageName
                    type : "package"
                    parent : nodeTree[jarName]
                    children : []
                    edgesOut : {}
                    edgesIn : {}
                
                nodeTree[jarName].children.push nodeTree[packageName]
            
            nodeTree[className] = 
                name : className
                type : node.type
                parent : nodeTree[packageName]
                #children : []
                edgesOut : {}
                edgesIn : {}
                #stuff from the orginal node
#                isAbstract : node["abstract"]
#                color : node.color
#                ctangle : node.ctangle
#                ptangle : node.ptangle
#                scc_cl_d : node.scc_cl_d
#                scc_cl_t : node.scc_cl_t
#                scc_ns_t : node.scc_ns_t
#                scc_ns_d : node.scc_ns_d
                
            nodeTree[packageName].children.push nodeTree[className]
            
            edgeNameToNodeObject[node.namespace + "." + node.name] = nodeTree[className]
        #END OF FOR EACH NODE
        console.timeEnd("generateNodeTree rawJson.nodes")
        
        console.time("generateNodeTree rawJson.edges")
        #this block of populates a list in each node with all the other nodes it is connected to
        for edge in rawJSON.edges
            srcClass = edgeNameToNodeObject[edge.src]
            srcPackage = srcClass.parent
            srcJar = srcPackage.parent
            
            tarClass = edgeNameToNodeObject[edge.tar]
            tarPackage = tarClass.parent
            tarJar = tarPackage.parent
                
            #if both src and tar are in the same jar, dont want to make any edges that terminate at a jar    
            if srcJar isnt tarJar
                #jar -> jar
                createLink(srcJar, tarJar, "j2j", edge)
                #jar -> package
                createLink(srcJar, tarPackage, "j2p", edge)
                #jar -> class
                createLink(srcJar, tarClass, "j2c", edge)
                #package -> jar
                createLink(srcPackage, tarJar, "p2j", edge)
                #class -> jar
                createLink(srcClass, tarJar, "c2j", edge)

            #if they have the same package, dont create any edges that terminate at the package
            if srcPackage isnt tarPackage
                #package -> package
                createLink(srcPackage, tarPackage, "p2p", edge)
                #package -> class
                createLink(srcPackage, tarClass, "p2c", edge)
                #class -> package
                createLink(srcClass, tarPackage, "c2p", edge)
            
            #always do the class -> class links
            #class -> class
            createLink(srcClass, tarClass, "c2c", edge)
        
        console.timeEnd("generateNodeTree rawJson.edges")
        
        ###for many systems there is only one jar
        if there is only one jar, we dont want to display it on its own
        we want to display the packages within, which is the same as selecting it###
        if nodeTree.root.children.length is 1
            max.selection.expandNode(nodeTree.root.children[0].name)
        
        return
    
    createLink = (src, tar, type, edge) ->
        tarName = tar.name
        srcName = src.name
        edgeType = edge.type
        if not src.edgesOut[tarName]
            src.edgesOut[tarName] = tar.edgesIn[srcName] = 
                source: src
                target: tar
                uses: if edgeType is "uses" then 1 else 0
                extends: if edgeType is "extends" then 1 else 0
                implements: if edgeType is "implements" then 1 else 0
                type: type                
        else 
            src.edgesOut[tarName][edgeType]++
            tar.edgesIn[srcName][edgeType]++
        return
    
    calculateNodesToBeIncluded = () ->
        console.time 'nodesToBeIncluded timer'
    
        #reset it
        nodesToBeIncluded = {}
    
        includeNode = (node) ->
            nodesToBeIncluded[node.name] = true #include the node
            if node.type isnt "jar"
                nodesToBeIncluded[node.parent.name] = true #include its parent if it is a class or package
                if node.type isnt "package"
                    nodesToBeIncluded[node.parent.parent.name] = true #include the jar if its a class
            
            
            for tarName of node.edgesOut
                nodesToBeIncluded[tarName] = true
            
            for srcName of node.edgesIn
                nodesToBeIncluded[srcName] = true
            
        for nodeName of max.selection.getSelectedNodes()
            node = nodeTree[nodeName]
            includeNode(node)
            
        selectedEdgeEnds = {}
        for edgeName of max.selection.getSelectedEdges()
            srcTarArray = edgeName.split(" ")
            srcNode = nodeTree[srcTarArray[0]]
            tarNode = nodeTree[srcTarArray[2]]
            selectedEdgeEnds[srcNode.name] = true
            selectedEdgeEnds[tarNode.name] = true
            includeNode(srcNode)
            includeNode(tarNode)
        console.timeEnd 'nodesToBeIncluded timer'
        return
       
    ###returns a hierarchial layout with all the nodes and their children
    each node has a name, and if it has children an array of children
    see https://github.com/mbostock/d3/wiki/Cluster-Layout###
    generateNodes = () ->
        
        console.time 'generateNodes timer'
        
        rootNode = 
            name : "root"
            children : []
            expanded : true
        
        for jar in nodeTree.root.children
        
            if $.isEmptyObject(nodesToBeIncluded) or nodesToBeIncluded[jar.name]
                jarChildren = []
                
                #we have to make a copy of the jar because otherwise we delete/change its children
                jarCopy =
                    name : jar.name
                    type : "jar"
                    edgesOut : jar.edgesOut
                    edgesIn : jar.edgesIn
                    expandable : true
                
                if max.selection.isExpandedNode(jar.name)
                    for Package in jar.children
                        if $.isEmptyObject(nodesToBeIncluded) or nodesToBeIncluded[Package.name]
                            packageChildren = []
                            
                            packageCopy = 
                                name : Package.name
                                type : "package"
                                parent : jarCopy
                                edgesOut : Package.edgesOut
                                edgesIn : Package.edgesIn
                                expandable: true
                                
                            
                            if max.selection.isExpandedNode(Package.name)
                                for Class in Package.children
                                    if $.isEmptyObject(nodesToBeIncluded) or nodesToBeIncluded[Class.name]
                                        #class doesn't have children so we dont need to make a copy of it
                                        classCopy = 
                                            name : Class.name
                                            type : Class.type
                                            parent : packageCopy
                                            edgesOut : Class.edgesOut
                                            edgesIn : Class.edgesIn
                                            collapsible : true
                                            selected : if max.selection.isSelectedNode(Class.name) then true
                                        packageChildren.push(classCopy)

                            
                            if nodeTree.root.children.length isnt 1
                                packageCopy.collapsible = true #if there is only one jar, we cant collapse the packages
                            if max.selection.isExpandedNode(Package.name)
                                packageCopy.expanded = true 
                            if max.selection.isSelectedNode(Package.name)
                                packageCopy.selected = true
                            if packageChildren.length != 0
                                packageCopy.children = packageChildren
                            
                            jarChildren.push packageCopy
                
                  
                
                if max.selection.isSelectedNode(jar.name)
                    jarCopy.selected = true                
                if max.selection.isExpandedNode(jar.name)
                    jarCopy.expanded = true     
                #attach the children with ones that should actually be included
                if jarChildren.length != 0
                    jarCopy.children = jarChildren
                
                rootNode.children.push jarCopy
        
        #max.selection.expandNode("root") #root node is expanded
        #max.state.saveState()
        
        
        
        
        nodes = cluster.nodes(rootNode)
        
        console.timeEnd 'generateNodes timer'
        
        return nodes       
        

    ###this returns an array of edges
    each edge has a source and a target
    it is important that both source and target have a parent object
    this method returns data that can go into bundle(edges)
    see https://github.com/mbostock/d3/wiki/Bundle-Layout###
    generateEdges = () ->
        
        console.time 'generateEdges timer'
        
        nodeMap = {}        
        ###Create a map of nodes so that they can be looked up when populating all the edges in the array###
        nodeMap[node.name] = node for node in nodes 
        
        countOfNodesForPerformanceTestingPurposes = 0        
        edges = []
        
        for node in nodes
            if node.name == "root" or node.expanded
                continue
            countOfNodesForPerformanceTestingPurposes++
            
            for tarNodeName, edge of node.edgesOut
                if nodeMap[tarNodeName]? and #we should only show it if is in the nodes we caluclated
                not nodeMap[tarNodeName].expanded and #if it is expanded we dont want anything going to or from it
                (max.selection.isSelectedNode(node.name, true) or max.selection.isSelectedNode(tarNodeName, true)) and
                #the above condition will return true if either src or tar is selected, OR no selection is made
                (selectedEdgeEnds[node.name] or selectedEdgeEnds[tarNodeName] or $.isEmptyObject(selectedEdgeEnds)) 
                #no edges are selected OR the src or tar is one of the selected edge ends
                    e = 
                        source : node
                        target : nodeMap[tarNodeName]
                        strength : 1
                        type : edge.type
                        uses: edge.uses
                        extends: edge.extends
                        implements: edge.implements
                    
                    if max.selection.isSelectedEdge("#{edge.source.name} #{edge.type} #{edge.target.name}")    
                        e.selected = true
                    
                    edges.push e
        
        
        console.log 'total number of nodes:' + countOfNodesForPerformanceTestingPurposes
        console.timeEnd 'generateEdges timer'
        return
               
    recalculate = () ->
        calculateNodesToBeIncluded()
        generateNodes()
        generateEdges()
        return
    
    #PUBLIC METHODS############################################################################################
    
    setJSON : (json) ->
        rawJSON = json
        generateNodeTree()
        recalculate()
        
    #public wrapper
    recalculate : () ->
        recalculate()
     
    getEdges : () ->
        edges
    
    getNodes : () ->
        nodes
        
    expandNode : (node) ->
        max.selection.expandNode(node.name)
        
        if max.selection.isSelectedNode(node.name) #if it is selected, we need to select all its children
            
            max.selection.deSelectNode(node.name)#deselect the node
            
            node = nodeTree[node.name] 
            #we want the orginal node from the node tree not the copied node with its children
            #which will have been removed or cut down
            
            for child in node.children #select all its chilrdren
                max.selection.selectNode(child.name)

        recalculate()
        max.state.saveState()
        
    collapseNode : (node) ->
        max.selection.expandNode(node.parent.name)
        
        node = nodeTree[node.name] 
        #we want the orginal node from the node tree not the copied node with its children
        #which will have been removed or cut down
        
        if node.parent.name isnt "root"
            childIsSelected = false
            for childNode in node.parent.children
                if max.selection.isSelectedNode(childNode.name)
                    childIsSelected = true
                    max.selection.deSelectNode(childNode.name)
            if childIsSelected
                max.selection.selectNode(node.parent.name)
        
        recalculate()
        max.state.saveState()
    
    ###This funciton takes a list of nodes that are selected
    It allows horizontal navigation throughout the view
    It will change the current nodes and edges values###
    toggleNodeSelection : (node, resetFirst) ->
        nodeName = node.name
        
        if max.selection.isSelectedNode(nodeName)
            max.selection.deSelectNode(nodeName, resetFirst)
        else
            max.selection.selectNode(nodeName, resetFirst)
        
        recalculate()
        max.state.saveState() 
        return
    
    toggleEdgeSelection : (edge, resetFirst) ->
        edgeName = edge.source.name + " #{edge.type} " + edge.target.name
        
        if max.selection.isSelectedEdge(edgeName)
            max.selection.deSelectEdge(edgeName, resetFirst)
        else
            max.selection.selectEdge(edgeName, resetFirst)
        
        recalculate()
        max.state.saveState() 
        return
    
    #resetSelections is called when the root bread crumb is clicked
    resetSelections : () ->
        max.selection.resetSelection()
        max.selection.resetExpansion()
        
        recalculate()
        max.state.saveState()         
        
     #this is called when a breadcrumb is clicked
     #nodeName is full name, eg jar@@package@@class
     selectSingleNode : (nodeName) ->
        if max.selection.isExpandedNode(nodeName)
            max.selection.expandNode(nodeName)
            
        
        max.selection.selectNode(nodeName, true)
        recalculate()
        max.state.saveState() 
     
        
        