import 'location.dart';

/// A class to represent node type information with key and display name
class NodeTypeInfo {
  /// The key used in the data model (e.g., "science")
  final String key;
  
  /// The display name shown in the UI (e.g., "Science & Research")
  final String displayName;
  
  /// Creates a new NodeTypeInfo
  const NodeTypeInfo({
    required this.key,
    required this.displayName,
  });
  
  @override
  String toString() => displayName;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NodeTypeInfo && other.key == key;
  }
  
  @override
  int get hashCode => key.hashCode;
}

/// A utility class for working with node types
class NodeTypeUtils {
  /// Gets the oracle table ID for a segment-specific node type roll
  static String getSegmentNodeTypeOracleId(LocationSegment segment) {
    switch (segment) {
      case LocationSegment.core:
        return 'core_segment_node_type';
      case LocationSegment.corpNet:
        return 'corporate_segment_node_type';
      case LocationSegment.govNet:
        return 'government_segment_node_type';
      case LocationSegment.darkNet:
        return 'underground_segment_node_type';
    }
  }
  
  /// Finds a NodeTypeInfo by its key in the provided list
  static NodeTypeInfo? findByKey(String key) {
    // This is a fallback method that will be used if no node types are provided
    // It's kept for backward compatibility with existing code
    return null;
  }
  
  /// Finds a NodeTypeInfo by its key in the provided list
  static NodeTypeInfo? findNodeTypeByKey(List<NodeTypeInfo> nodeTypes, String key) {
    try {
      return nodeTypes.firstWhere((info) => info.key == key);
    } catch (e) {
      return null;
    }
  }
  
  /// Randomly selects a node type from the provided list
  static NodeTypeInfo? getRandomNodeType(List<NodeTypeInfo> nodeTypes) {
    if (nodeTypes.isEmpty) return null;
    
    final random = DateTime.now().millisecondsSinceEpoch % nodeTypes.length;
    return nodeTypes[random];
  }
}
