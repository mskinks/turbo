var path = require("path");
var webpack = require("webpack");
var ExtractTextPlugin = require("extract-text-webpack-plugin");

// TODO depending on config, js-inline css when on dev server and
// split out into css themes for dist

module.exports = {
    entry: "./src/turbo.ls",
    output: {
        path: path.join(__dirname, 'dist'),
        publicPath: '/',
        filename: "turbo.js"
    },
    plugins: [
        new webpack.ProvidePlugin({
            _: "lodash",
            m: "mithril",
            state: "state",
            conn: "connection"
        }),
        new webpack.IgnorePlugin(/^\.\/locale$/, /moment$/)
        // new ExtractTextPlugin("themes/[name].css")
    ],
    resolve: {
        modulesDirectories: ["src", "node_modules"],
        extensions: ["", ".webpack.js", ".web.js", ".js", ".ls"]
    },
    module: {
        loaders: [
            { test: /\.ls$/, loader: "livescript" },
            { test: /\.less$/, loader: "style!css!less" }
            // { test: /\.css$/,  loader: ExtractTextPlugin.extract("style-loader", "css-loader") },
            // { test: /\.less$/,  loader: ExtractTextPlugin.extract("style-loader", "css-loader!less-loader") }
        ],
    }
};
