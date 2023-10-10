/// Aliyun function compute
library;

import 'dart:io';

import 'package:process_run/shell_run.dart';
import 'package:tekartik_app_node_build/src/run.dart';

/// Compile bin/main.dart to deploy/functions/index.js
Future afcNodeBuild(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  await nodeBuild(directory: directory);
  await afcNodeCopyToDeploy(
      directory: directory, deployDirectory: deployDirectory);
}

Future afcNodeServe({String directory = 'deploy'}) async {
  var shell = Shell(workingDirectory: directory);
  await shell.run('firebase serve');
}

/// Convert main.dart to index.js
Future afcNodeCopyToDeploy(
    {String directory = 'bin', String deployDirectory = 'deploy'}) async {
  var src = File('build/$directory/main.dart.js');
  Future copy() async {
    var file = await src.copy('$deployDirectory/index.js');
    print('copied to $file ${file.statSync()}');
  }

  try {
    await copy();
  } catch (e) {
    await Directory(deployDirectory).create(recursive: true);
    await copy();
  }
}

class AfcDeployResult {
  // Function url
  final String? url;

  AfcDeployResult._({this.url});
}

/// Deploy and return the result (including the function name)
Future<AfcDeployResult> afcNodeDeploy(
    {String deployDirectory = 'deploy'}) async {
  var shell = Shell(workingDirectory: 'deploy');
  var lines = (await shell.run('fun deploy')).outLines;
  String? foundUrl;
  // Extract from 'url: https://xxxxx.eu-central-1.fc.aliyuncs.com/xxxxxx/'
  for (var line in lines) {
    var text = line.trim();
    var parts = text.split(' ');
    if (parts[0] == 'url:' && parts.length > 1) {
      foundUrl = parts[1];
    }
  }
  return AfcDeployResult._(url: foundUrl);
}
/*
using template: template.yml
using region: cn-shanghai
using accountId: ***********4243
using accessKeyId: ***********pTkn
using timeout: 300

Collecting your services information, in order to caculate devlopment changes...

Resources Changes(Beta version! Only FC resources changes will be displayed):

┌──────────┬──────────────────────────────┬────────┬──────────┐
│ Resource │ ResourceType                 │ Action │ Property │
├──────────┼──────────────────────────────┼────────┼──────────┤
│ football │ Aliyun::Serverless::Function │ Modify │ CodeUri  │
└──────────┴──────────────────────────────┴────────┴──────────┘

Waiting for service hublot_haw_dev to be deployed...
	Waiting for function football to be deployed...
		Waiting for packaging function football code...
		The function football has been packaged. A total of 1 file were compressed and the final size was 174.17 KB
		Waiting for HTTP trigger httpTrigger to be deployed...
		triggerName: httpTrigger
		methods: [ 'POST', 'GET' ]
		url: https://xxxxxx.xxxxxxx.fc.aliyuncs.com/2016-08-15/proxy/xxxxx/xxxxx/
		Http Trigger will forcefully add a 'Content-Disposition: attachment' field to the response header, which cannot be overwritten
		and will cause the response to be downloaded as an attachment in the browser. This issue can be avoided by using CustomDomain.

		trigger httpTrigger deploy success
	function football deploy success
service hublot_haw_dev deploy success
 */
