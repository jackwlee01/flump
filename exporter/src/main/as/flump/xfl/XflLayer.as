//
// Flump - Copyright 2012 Three Rings Design

package flump.xfl {

import flump.mold.KeyframeMold;
import flump.mold.LayerMold;

import com.threerings.util.XmlUtil;

public class XflLayer
{
    use namespace xflns;

    public static function parse (lib :XflLibrary, baseLocation :String, xml :XML, flipbook :Boolean) :LayerMold {
        const layer :LayerMold = new LayerMold();
        layer.name = XmlUtil.getStringAttr(xml, "name");
        layer.flipbook = flipbook;
        layer.location = baseLocation + ":" + layer.name
        for each (var frameEl :XML in xml.frames.DOMFrame) {
            layer.keyframes.push(XflKeyframe.parse(lib, layer.location, frameEl, flipbook));
        }
        if (layer.keyframes.length == 0) lib.addError(layer, ParseError.INFO, "No keyframes on layer");

        // normalize rotations, so that we always rotate the shortest distance between
        // two angles (we don't want to rotate more than Math.PI)
        // TODO: support keyframes with rotations >= TWO_PI
        for (var ii :int = 0; ii < layer.keyframes.length - 1; ++ii) {
            var kf :KeyframeMold = layer.keyframes[ii];
            var nextKf :KeyframeMold = layer.keyframes[ii+1];
            if (kf.rotation + Math.PI < nextKf.rotation) {
                nextKf.rotation -= Math.PI * 2;
            } else if (kf.rotation - Math.PI > nextKf.rotation) {
                nextKf.rotation += Math.PI * 2;
            }
        }
        return layer;
    }

}
}