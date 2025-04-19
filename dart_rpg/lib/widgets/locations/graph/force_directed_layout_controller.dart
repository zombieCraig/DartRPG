import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../models/location.dart';

/// Callback for simulation state changes
typedef SimulationStateCallback = void Function(bool isSimulating);

/// A controller for managing force-directed layout of location nodes
class ForceDirectedLayoutController {
  /// Physics parameters
  final double repulsionStrength;
  final double attractionStrength;
  final double damping;
  final double maxVelocity;
  final double minEnergyThreshold;
  
  /// Callback for when simulation starts or stops
  final SimulationStateCallback? onSimulationStateChanged;
  
  /// Node data
  final Map<String, ForceNode> nodes = {};
  
  /// Connection data
  final Map<String, List<String>> connections = {};
  
  /// Animation controller for continuous simulation
  late AnimationController animationController;
  
  /// Whether the simulation is running
  bool _isSimulating = false;
  
  /// The last time the forces were calculated
  DateTime _lastCalculationTime = DateTime.now();
  
  /// The total energy in the system
  double _totalEnergy = 0.0;
  
  /// Minimum distance between nodes
  final double minNodeDistance;
  
  /// Maximum simulation time in seconds
  final double maxSimulationTime;
  
  /// Time when simulation started
  DateTime? _simulationStartTime;
  
  /// Creates a new ForceDirectedLayoutController
  ForceDirectedLayoutController({
    this.repulsionStrength = 20000.0, // Doubled repulsion for more separation
    this.attractionStrength = 0.2, // Reduced attraction for less clustering
    this.damping = 0.9, // Increased damping for smoother movement
    this.maxVelocity = 100.0, // Increased max velocity for more dynamic movement
    this.minEnergyThreshold = 1.0, // Increased threshold to allow settling
    this.minNodeDistance = 250.0, // Increased minimum distance between nodes
    this.maxSimulationTime = 10.0, // Maximum simulation time in seconds
    this.onSimulationStateChanged,
    required TickerProvider vsync,
  }) {
    // Initialize animation controller
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 1),
    )..addListener(_onAnimationTick);
  }
  
  /// Initializes the force-directed layout with locations
  void initialize(List<Location> locations, Map<String, Offset> initialPositions) {
    // Clear existing data
    nodes.clear();
    connections.clear();
    
    // Create force nodes for each location
    for (final location in locations) {
      // Always use the saved position from the location if available
      // This ensures we respect the positions saved in the database
      Offset position;
      if (location.x != null && location.y != null) {
        position = Offset(location.x!, location.y!);
      } else {
        position = initialPositions[location.id] ?? Offset.zero;
      }
      
      nodes[location.id] = ForceNode(
        id: location.id,
        position: position,
        segment: location.segment,
      );
      
      // Store connections
      connections[location.id] = List.from(location.connectedLocationIds);
    }
  }
  
  /// Starts the force-directed layout simulation
  void startSimulation() {
    if (_isSimulating) {
      return;
    }
    
    _isSimulating = true;
    _lastCalculationTime = DateTime.now();
    _simulationStartTime = DateTime.now();
    animationController.repeat();
    
    // Notify callback that simulation has started
    if (onSimulationStateChanged != null) {
      onSimulationStateChanged!(true);
    }
  }
  
  /// Stops the force-directed layout simulation
  void stopSimulation() {
    if (!_isSimulating) {
      return;
    }
    
    _isSimulating = false;
    animationController.stop();
    
    // Notify callback that simulation has stopped
    if (onSimulationStateChanged != null) {
      onSimulationStateChanged!(false);
    }
  }
  
  /// Applies a repulsive force from a specific point
  void applyRepulsiveForce(String nodeId, Offset force) {
    final node = nodes[nodeId];
    if (node == null) return;
    
    node.applyForce(force);
    
    // Propagate force to connected nodes with diminishing effect
    _propagateForce(nodeId, force * 0.5, {nodeId});
  }
  
  /// Propagates a force to connected nodes
  void _propagateForce(String nodeId, Offset force, Set<String> visitedNodes) {
    final connectedIds = connections[nodeId] ?? [];
    
    for (final connectedId in connectedIds) {
      if (visitedNodes.contains(connectedId)) continue;
      
      final connectedNode = nodes[connectedId];
      if (connectedNode == null) continue;
      
      connectedNode.applyForce(force);
      
      // Recursively propagate with diminishing effect
      visitedNodes.add(connectedId);
      _propagateForce(connectedId, force * 0.5, visitedNodes);
    }
  }
  
  /// Calculates forces for all nodes
  void calculateForces() {
    // Reset forces
    for (final node in nodes.values) {
      node.force = Offset.zero;
    }
    
    // Calculate repulsive forces between all pairs of nodes
    final nodeIds = nodes.keys.toList();
    for (int i = 0; i < nodeIds.length; i++) {
      final nodeId1 = nodeIds[i];
      final node1 = nodes[nodeId1]!;
      
      for (int j = i + 1; j < nodeIds.length; j++) {
        final nodeId2 = nodeIds[j];
        final node2 = nodes[nodeId2]!;
        
        _calculateRepulsionForce(node1, node2);
      }
    }
    
    // Calculate attractive forces for connected nodes
    for (final sourceId in connections.keys) {
      final sourceNode = nodes[sourceId];
      if (sourceNode == null) continue;
      
      for (final targetId in connections[sourceId] ?? []) {
        final targetNode = nodes[targetId];
        if (targetNode == null) continue;
        
        _calculateAttractionForce(sourceNode, targetNode);
      }
    }
    
    // Apply segment-based forces
    _calculateSegmentForces();
    
    // Apply boundary forces to keep nodes within the canvas
    for (final node in nodes.values) {
      _calculateBoundaryForce(node);
    }
  }
  
  /// Calculates repulsion force between two nodes
  void _calculateRepulsionForce(ForceNode node1, ForceNode node2) {
    final delta = node1.position - node2.position;
    final distance = delta.distance;
    
    // Avoid division by zero
    if (distance < 0.1) {
      // Nodes are too close, apply a strong repulsive force in a random direction
      final random = math.Random();
      final angle = random.nextDouble() * 2 * math.pi;
      final randomForce = Offset(
        math.cos(angle) * repulsionStrength * 0.1,
        math.sin(angle) * repulsionStrength * 0.1
      );
      
      node1.applyForce(randomForce);
      node2.applyForce(-randomForce);
      return;
    }
    
    // Apply stronger repulsion when nodes are closer than the minimum distance
    double repulsionFactor;
    if (distance < minNodeDistance) {
      // Use a stronger repulsion for nodes that are too close
      repulsionFactor = repulsionStrength * (minNodeDistance / distance) / (distance * distance);
    } else {
      // Normal repulsion for nodes at acceptable distances
      repulsionFactor = repulsionStrength / (distance * distance);
    }
    
    // Normalize the delta vector and scale by repulsion factor
    final force = delta / distance * repulsionFactor;
    
    // Apply forces in opposite directions
    node1.applyForce(force);
    node2.applyForce(-force);
  }
  
  /// Calculates attraction force between two connected nodes
  void _calculateAttractionForce(ForceNode node1, ForceNode node2) {
    final delta = node2.position - node1.position;
    final distance = delta.distance;
    
    // Avoid division by zero
    if (distance < 0.1) return;
    
    // Calculate attraction force (proportional to distance)
    final attractionFactor = attractionStrength * distance;
    
    // Normalize the delta vector and scale by attraction factor
    final force = delta / distance * attractionFactor;
    
    // Apply forces in opposite directions
    node1.applyForce(force);
    node2.applyForce(-force);
  }
  
  /// Calculates segment-based forces
  void _calculateSegmentForces() {
    // Group nodes by segment
    final Map<LocationSegment, List<ForceNode>> nodesBySegment = {};
    
    for (final node in nodes.values) {
      if (!nodesBySegment.containsKey(node.segment)) {
        nodesBySegment[node.segment] = [];
      }
      nodesBySegment[node.segment]!.add(node);
    }
    
    // Calculate segment centers
    final Map<LocationSegment, Offset> segmentCenters = {};
    
    for (final entry in nodesBySegment.entries) {
      final segment = entry.key;
      final segmentNodes = entry.value;
      
      if (segmentNodes.isEmpty) continue;
      
      // Calculate average position
      Offset sum = Offset.zero;
      for (final node in segmentNodes) {
        sum += node.position;
      }
      
      segmentCenters[segment] = sum / segmentNodes.length.toDouble();
    }
    
    // Apply attraction to segment center
    for (final node in nodes.values) {
      final segmentCenter = segmentCenters[node.segment];
      if (segmentCenter == null) continue;
      
      final delta = segmentCenter - node.position;
      final distance = delta.distance;
      
      // Avoid division by zero
      if (distance < 0.1) continue;
      
      // Calculate segment attraction force (weak)
      final segmentAttractionFactor = attractionStrength * 0.5 * distance;
      
      // Normalize the delta vector and scale by attraction factor
      final force = delta / distance * segmentAttractionFactor;
      
      // Apply force
      node.applyForce(force);
    }
  }
  
  /// Calculates boundary force to keep node within canvas
  void _calculateBoundaryForce(ForceNode node) {
    // Canvas boundaries (assuming 2000x2000 with center at 0,0)
    const double boundary = 950.0;
    
    // X-axis boundary forces
    if (node.position.dx < -boundary) {
      node.applyForce(Offset(repulsionStrength * 0.1, 0));
    } else if (node.position.dx > boundary) {
      node.applyForce(Offset(-repulsionStrength * 0.1, 0));
    }
    
    // Y-axis boundary forces
    if (node.position.dy < -boundary) {
      node.applyForce(Offset(0, repulsionStrength * 0.1));
    } else if (node.position.dy > boundary) {
      node.applyForce(Offset(0, -repulsionStrength * 0.1));
    }
  }
  
  /// Updates node positions based on forces
  void updatePositions(double deltaTime) {
    _totalEnergy = 0.0;
    
    for (final node in nodes.values) {
      // Update velocity based on force and damping
      node.velocity += node.force * deltaTime;
      node.velocity *= damping;
      
      // Limit velocity to prevent instability
      if (node.velocity.distance > maxVelocity) {
        node.velocity = node.velocity / node.velocity.distance * maxVelocity;
      }
      
      // Update position
      node.position += node.velocity * deltaTime;
      
      // Ensure position is within bounds
      node.position = Offset(
        math.max(-950.0, math.min(950.0, node.position.dx)),
        math.max(-950.0, math.min(950.0, node.position.dy)),
      );
      
      // Accumulate energy
      _totalEnergy += node.velocity.distanceSquared;
    }
  }
  
  /// Gets the current positions of all nodes
  Map<String, Offset> getNodePositions() {
    final positions = <String, Offset>{};
    
    for (final entry in nodes.entries) {
      positions[entry.key] = entry.value.position;
    }
    
    return positions;
  }
  
  /// Callback for animation tick
  void _onAnimationTick() {
    if (!_isSimulating) {
      return;
    }
    
    // Calculate time delta
    final now = DateTime.now();
    final deltaTime = now.difference(_lastCalculationTime).inMilliseconds / 1000.0;
    _lastCalculationTime = now;
    
    // Skip if delta time is too large (e.g., after app was in background)
    if (deltaTime > 0.1) {
      return;
    }
    
    // Check if maximum simulation time has been reached
    if (_simulationStartTime != null) {
      final elapsedSeconds = now.difference(_simulationStartTime!).inMilliseconds / 1000.0;
      if (elapsedSeconds >= maxSimulationTime) {
        stopSimulation();
        return;
      }
    }
    
    // Calculate forces and update positions
    calculateForces();
    updatePositions(deltaTime);
    
    // Check if system has reached equilibrium
    if (_totalEnergy < minEnergyThreshold) {
      // Stop the simulation when energy is below threshold
      stopSimulation();
    }
  }
  
  /// Adds a small random jitter force to each node
  void _addRandomJitter({double strength = 10.0}) {
    final random = math.Random();
    for (final node in nodes.values) {
      // Create a random force in a random direction
      final angle = random.nextDouble() * 2 * math.pi;
      final magnitude = random.nextDouble() * strength;
      final jitterForce = Offset(
        math.cos(angle) * magnitude,
        math.sin(angle) * magnitude
      );
      
      // Apply the jitter force
      node.applyForce(jitterForce);
    }
  }
  
  /// Whether the simulation is currently running
  bool get isSimulating => _isSimulating;
  
  /// The total energy in the system
  double get totalEnergy => _totalEnergy;
  
  /// Disposes of resources
  void dispose() {
    animationController.dispose();
  }
}

/// A node in the force-directed layout
class ForceNode {
  /// The ID of the node
  final String id;
  
  /// The current position of the node
  Offset position;
  
  /// The current velocity of the node
  Offset velocity = Offset.zero;
  
  /// The current force applied to the node
  Offset force = Offset.zero;
  
  /// The segment of the node
  final LocationSegment segment;
  
  /// Creates a new ForceNode
  ForceNode({
    required this.id,
    required this.position,
    required this.segment,
  });
  
  /// Applies a force to the node
  void applyForce(Offset additionalForce) {
    force += additionalForce;
  }
}
