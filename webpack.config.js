var path = require("path");
var webpack = require("webpack");

module.exports = {
    entry: "./src/turbo.ls",
    output: {
        path: path.join(__dirname, 'dist'),
        publicPath: '/static/',
        filename: "turbo.js"
    },
    plugins: [
        new webpack.ProvidePlugin({
            _: "lodash",
            m: "mithril"
        })
    ],
    resolve: {
        modulesDirectories: ["src", "node_modules"],
        extensions: ["", ".webpack.js", ".web.js", ".js", ".ls"]
    },
    module: {
        loaders: [
            { test: /\.ls$/, loader: "livescript" },
            { test: /\.less$/, loader: "style!css!less" }
        ],
    }
};
