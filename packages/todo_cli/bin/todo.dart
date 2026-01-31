import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  final targetPath = args.isNotEmpty 
      ? p.normalize(p.absolute(args.first)) 
      : Directory.current.path;

  print('Scanning for Todos in: $targetPath ...\n');

  final collection = AnalysisContextCollection(
    includedPaths: [targetPath],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  int count = 0;

  for (final context in collection.contexts) {
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart')) continue;

      final result = await context.currentSession.getResolvedUnit(filePath);
      final visitor = _TodoVisitor(filePath, targetPath);

      if (result is ResolvedUnitResult) {
        result.libraryElement.visitChildren(visitor);
      }
    }
  }

  print('\nScan complete. Found $count ToDos.');
}

class _TodoVisitor extends RecursiveElementVisitor2 {
  final String filePath;
  final String rootPath;

  _TodoVisitor(this.filePath, this.rootPath);

  @override
  visitClassElement(ClassElement element) {
    return _processTodoAnnotations(element);
  }

  void _processTodoAnnotations(Element element) {
    final annotations = element.metadata.annotations;
    final todos = annotations
      .where((e) => e.element?.displayName == 'Todo')
      .toList();

    for (final todo in todos) {
      _printReport(element, todo);
    }
  }

  void _printReport(Element element, ElementAnnotation todo) {
    final value = todo.computeConstantValue();
    final description = value?.getField('description')?.toStringValue();
    final priority = value?.getField('priority')?.toStringValue();
    final relativePath = p.relative(filePath, from: rootPath);

    final priorityMessage = priority != null 
      ? '(priority: $priority'
      : null;

    print('File: $relativePath. Todo: $description $priorityMessage for element: ${element.displayName}\n');
  }
}