//
// Flump - Copyright 2013 Flump Authors

package flump.export {

import aspire.util.F;
import aspire.util.XmlUtil;

import flash.filesystem.File;
import flash.utils.IDataOutput;

import flump.Util;
import flump.mold.LibraryMold;
import flump.mold.MovieMold;
import flump.mold.TextureGroupMold;
import flump.xfl.XflLibrary;

public class XMLFormat extends PublishFormat
{
    public static const NAME :String = "XML";

    public function XMLFormat (destDir :File, libs :Vector.<XflLibrary>, conf :ExportConf,
            projectName :String) {
        super(destDir, libs, conf, projectName);
        _prefix = conf.name + "/" + location + "/";
        _metaFile =  _destDir.resolvePath(_prefix + "resources.xml");
    }

    override public function get modified () :Boolean {
        return !_metaFile.exists || Util.bytesToXML(Files.read(_metaFile)).@md5 != md5;
    }

    override public function publish () :void {
        const libExportDir :File = _destDir.resolvePath(_prefix);
        // Ensure any previously generated atlases don't linger
        if (libExportDir.exists) libExportDir.deleteDirectory(/*deleteDirectoryContents=*/true);
        libExportDir.createDirectory();

        const atlases :Vector.<Atlas> = createAtlases(_prefix);
        for each (var atlas :Atlas in atlases) {
            Files.write(
                _destDir.resolvePath(atlas.filename),
                F.bind(AtlasUtil.writePNG, atlas, F._1));
        }

        const xml :XML = <resources md5={md5} isNamespaced={_libs.length > 1}/>;
        const prefix :String = location + "/";
        const libraryMold :LibraryMold = createMold(atlases);
        for each (var movie :MovieMold in libraryMold.movies) {
            var movieXml :XML = movie.scale(_conf.scale).toXML();
            movieXml.@name = prefix + movieXml.@name;
            movieXml.@frameRate = _libs[0].frameRate;
            for each (var kf :XML in movieXml..kf) {
                if (XmlUtil.hasAttr(kf, "ref")) kf.@ref = prefix + kf.@ref;
            }
            xml.appendChild(movieXml);
        }

        const groupsXml :XML = <textureGroups/>;
        xml.appendChild(groupsXml);
        for each (var group :TextureGroupMold in libraryMold.textureGroups) {
            groupsXml.appendChild(group.toXML());
        }

        for each (var texture :XML in groupsXml..texture) texture.@name = prefix + texture.@name;

        // For XML, the pretty printing option is a static, so save & restore
        const oldPretty :Boolean = XML.prettyPrinting;
        XML.prettyPrinting = _conf.prettyPrint;
        const xmlString :String = xml.toString();
        XML.prettyPrinting = oldPretty;
        Files.write(_metaFile, function (out :IDataOutput) :void { out.writeUTFBytes(xmlString); });
    }


    protected var _prefix :String;
    protected var _metaFile :File;
}
}
