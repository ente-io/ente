/**
 * 
 * Run 'grunt' to generate JS and CSS in folder 'dist' and site in folder '_site'
 * *
 * Run 'grunt watch' to automatically regenerate '_site' when you change files in 'src' or in 'website'
 * 
 */

module.exports = function(grunt) {

  'use strict';

  var jekyllConfig = "isLocal : false \r\n"+
      "permalink: /:title/ \r\n"+
      "exclude: ['.json', '.rvmrc', '.rbenv-version', 'README.md', 'Rakefile'," +
                "'changelog.md', 'compiler.jar', 'private', '.htaccess'," + 
                "'photoswipe.sublime-project', 'photoswipe.sublime-workspace'] \r\n"+

      "auto: true \r\n"+
      "pswpversion: <%= pkg.version %> \r\n"+
      "siteversion: 1.0.4 \r\n"+
      "markdown: redcarpet \r\n"+
      "kramdown: \r\n"+
      "  input: GFM \r\n";

  grunt.initConfig({

    pkg: grunt.file.readJSON('photoswipe.json'),

    banner: '/*! PhotoSwipe - v<%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>; */\n',

    defaultUIBanner:  '/*! PhotoSwipe Default UI - <%= pkg.version %> - ' +
      '<%= grunt.template.today("yyyy-mm-dd") %>\n' +
      '<%= pkg.homepage ? "* " + pkg.homepage + "\\n" : "" %>' +
      '* Copyright (c) <%= grunt.template.today("yyyy") %> <%= pkg.author.name %>; */\n',

    // Task configuration.
    clean: {
      files: ['dist']
    },
    
    sass: {                            
      dist: {                      
        files: {      
          'dist/photoswipe.css': 'src/css/main.scss',
          'dist/default-skin/default-skin.css': 'src/css/default-skin/default-skin.scss'
        }
      }
    },

    // https://github.com/nDmitry/grunt-autoprefixer
    autoprefixer: { 
      options: {
        browsers: ['last 3 versions', 'android 3', 'ie 9', 'bb 10']
      },
      no_dest: {
        src: ['dist/photoswipe.css', 'dist/default-skin/default-skin.css']
      }
    },

    jshint: {
      all: [
        'Gruntfile.js',
        'dist/photoswipe.js',
        'dist/photoswipe-ui-default.js'
      ],
      options: {
        jshintrc: '.jshintrc'
      }
    },

    pswpbuild: {
      all: {
        src: [
          'framework-bridge',
          'core',
          'gestures',
          'show-hide-transition',
          'items-controller',
          'tap',
          'desktop-zoom',
          'history'
        ],
        basePath: 'src/js/',
        dest: 'dist/photoswipe.js',
        uidest: 'dist/photoswipe-ui-default.js',
        banner: '<%= banner %>',
        defaultUIBanner: '<%= defaultUIBanner %>'
      }
    },

    jekyll: {
      dev: {
        options: {
          src: 'website',
          dest: '_site',
          url: 'local',
          raw: jekyllConfig + "url: local"
        }
        
      },
      production: {
        options: {
          src: 'website',
          dest: '_production',
          url: 'production',
          raw: jekyllConfig + "url: production"
        }
      }
    },

    copy: {
      dev: {
        files: [
          {src: ['src/css/default-skin/default-skin.svg'], dest: 'dist/default-skin/default-skin.svg'},
          {src: ['src/css/default-skin/default-skin.png'], dest: 'dist/default-skin/default-skin.png'},
          {src: ['src/css/default-skin/preloader.gif'], dest: 'dist/default-skin/preloader.gif'},
          {expand: true, src: ['dist/**'], dest: '_site/'}
        ]
      },
      main: {
        files: [
          {expand: true, src: ['dist/**'], dest: 'website/'}
        ]
      }

    },

    uglify: {
      my_target: {
        files: {
          'dist/photoswipe.min.js': ['dist/photoswipe.js'],
          'dist/photoswipe-ui-default.min.js': ['dist/photoswipe-ui-default.js']
        },
        preserveComments: /^!/i
      },
      options: {
        preserveComments: /^!/i
      }
    },

    watch: { // for development run 'grunt watch'
      jekyll: {
        files: ['website/**', 'website/documentation/**', '_includes/**'],
        tasks: ['jekyll:dev', 'copy:dev']
      },
      files: ['src/**'],
      tasks: [ 'sass', 'autoprefixer', 'pswpbuild', 'copy:dev', 'uglify']
    },

    cssmin: {
      compress: {
        files: {
          "website/site-assets/all.min.css": ["website/site-assets/site.css", "website/dist/photoswipe.css"]
        }
      }
    },

    svgmin: {
      dist: {
        files: {
          'src/css/default-skin/default-skin.svg': 'src/css/default-skin/default-skin.svg'
        }
      }
    }


  });


  // grunt pswpbuild --pswp-exclude=ajax,image
  grunt.task.registerMultiTask('pswpbuild', 'Makes PhotoSwipe core JS file.', function() {

    var files = this.data.src,
        includes = grunt.option('pswp-exclude'),
        basePath = this.data.basePath,
        newContents = this.data.banner;

    newContents += "(function (root, factory) { \n"+
      "\tif (typeof define === 'function' && define.amd) {\n" +
        "\t\tdefine(factory);\n" +
      "\t} else if (typeof exports === 'object') {\n" +
        "\t\tmodule.exports = factory();\n" +
      "\t} else {\n" +
        "\t\troot.PhotoSwipe = factory();\n" +
      "\t}\n" +
    "})(this, function () {\n\n" +
      "\t'use strict';\n"+
      "\tvar PhotoSwipe = function(template, UiClass, items, options){\n";
      

    if(includes) {
      includes = includes.split(/[\s,]+/); // 'a,b,c' => ['a','b','c']
      var removeA = function (arr) {
          var what, a = arguments, L = a.length, ax;
          while (L > 1 && arr.length) {
              what = a[--L];
              while ((ax= arr.indexOf(what)) !== -1) {
                  arr.splice(ax, 1);
              }
          }
          return arr;
      };

      includes.forEach(function( name ) {
        if(name) {
           
           grunt.log.writeln( 'removed "'+name +'"' );
           files = removeA(files, name);
         }
      });
    }
    
    grunt.log.writeln( 'Your build is made of:'+files );

    files.forEach(function( name ) {
      // Wrap each module with a pience of code to be able to exlude it, stolen for modernizr.com
      newContents += "\n/*>>"+name+"*/\n"; 
      newContents += grunt.file.read( basePath + name + '.js' ) + '\n';
      newContents += "\n/*>>"+name+"*/\n"; 
    });


    newContents+= "\tframework.extend(self, publicMethods); };\n";
    newContents+= "\treturn PhotoSwipe;\n";
    newContents+= "});";


    grunt.file.write( this.data.dest, newContents );

    var uiContents = grunt.file.read( basePath + 'ui/photoswipe-ui-default.js' );
    uiContents = this.data.defaultUIBanner + uiContents;
    grunt.file.write( this.data.uidest, uiContents );
  });




  // These plugins provide necessary tasks.
  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-contrib-concat');
  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-jshint');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.loadNpmTasks('grunt-sass');
  grunt.loadNpmTasks('grunt-autoprefixer');
  grunt.loadNpmTasks('grunt-contrib-copy');
  grunt.loadNpmTasks('grunt-jekyll');
  grunt.loadNpmTasks('grunt-contrib-cssmin');
  grunt.loadNpmTasks('grunt-svgmin');

  // Default task.
  grunt.registerTask('default', ['sass', 'autoprefixer', 'pswpbuild','uglify', 'copy', 'jekyll:dev']);

  grunt.registerTask('production', ['sass', 'autoprefixer', 'pswpbuild', 'uglify', 'copy', 'cssmin', 'jekyll:production']);
  grunt.registerTask('nosite', ['sass', 'autoprefixer', 'pswpbuild', 'uglify']);
  grunt.registerTask('hint', ['jshint']);

};