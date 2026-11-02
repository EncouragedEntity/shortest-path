import 'package:flutter/material.dart';

import 'features/path_finding/data/api_path_operations.dart';

import 'app.dart';

void main() => runApp(const WebsparkApp(operations: ApiPathOperations()));
