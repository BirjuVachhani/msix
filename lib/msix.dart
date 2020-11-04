import 'dart:io';
import 'package:path/path.dart';
import 'src/utils.dart';
import 'src/configuration.dart';
import 'src/constants.dart';
import 'src/msixFiles.dart';

class Msix {
  Configuration _configuration;
  MsixFiles _msixFiles;

  Msix() {
    print(
        'MsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsixMsix');
    _configuration = Configuration();
    _msixFiles = MsixFiles(_configuration);
  }

  /// Create and sign msix installer file
  Future<void> createMsix(List<String> args) async {
    await _configuration.getConfigValues();
    await _configuration.validateConfigValues();
    await _msixFiles.createIconsFolder();
    await _msixFiles.copyIcons();
    await _msixFiles.generateAppxManifest();
    await _msixFiles.copyVCLibsFiles();

    print(white('packing....    '));
    var packResults = await _pack();

    if (packResults.stderr.toString().length > 0) {
      print(red(packResults.stdout));
      print(red(packResults.stderr));
      exit(0);
    } else if (packResults.exitCode != 0) {
      print(red(packResults.stdout));
      exit(0);
    }
    print(green('done!'));

    print(white('singing....    '));
    var signResults = await _sign();

    if (!signResults.stdout.toString().contains('Number of files successfully Signed: 1') &&
        signResults.stderr.toString().length > 0) {
      print(red(signResults.stdout));
      print(red(signResults.stderr));

      if (signResults.stdout.toString().contains('Error: SignerSign() failed.') &&
          !isNullOrStringNull(_configuration.certificateSubject)) {
        printCertificateSubjectHelp();
      }

      exit(0);
    } else if (packResults.exitCode != 0) {
      print(red(signResults.stdout));
      exit(0);
    }
    print(green('done!'));

    await _msixFiles.cleanTemporaryFiles();

    print('');
    print(green('Msix installer created in:'));
    print('${_configuration.buildFilesFolder}'.replaceAll('/', r'\'));

    if (_configuration.isUseingTestCertificate) printTestCertificateHelp();
  }

  Future<ProcessResult> _pack() async {
    var msixPath = '${_configuration.buildFilesFolder}\\${_configuration.appName}.msix';
    var makeappxPath =
        '${_configuration.msixToolkitPath()}/Redist.${_configuration.architecture}/makeappx.exe';

    if (await File(msixPath).exists()) await File(msixPath).delete();

    return await Process.run(makeappxPath, [
      'pack',
      '/v',
      '/o',
      '/d',
      _configuration.buildFilesFolder,
      '/p',
      msixPath,
    ]);
  }

  Future<ProcessResult> _sign() async {
    var signtoolPath =
        '${_configuration.msixToolkitPath()}/Redist.${_configuration.architecture}/signtool.exe';

    if (extension(_configuration.certificatePath) == '.pfx') {
      return await Process.run(signtoolPath, [
        'sign',
        '/fd',
        'SHA256',
        '/a',
        '/f',
        _configuration.certificatePath,
        '/p',
        _configuration.certificatePassword,
        '${_configuration.buildFilesFolder}\\${_configuration.appName}.msix',
      ]);
    } else {
      return await Process.run(signtoolPath, [
        'sign',
        '/fd',
        'SHA256',
        '/a',
        _configuration.certificatePath,
        '${_configuration.buildFilesFolder}\\${_configuration.appName}.msix',
      ]);
    }
  }
}