# ros/package.rb
#
# License: BSD
#
# Copyright (C) 2012  Takashi Ogura <t.ogura@gmail.com>
#
# == ROS Package manager
#
# This is used for adding RUBYLIB path.
# This file will provide rospack functions, in the future
#

require 'rexml/document'

module ROS

  # This is used for adding RUBYLIB path.
  #
  class Package

    ##
    # path of rospack cache
    #
    @@cache_path = "#{ENV['HOME']}/.ros/rospack_cache"

    ##
    # at first check the rospack's cache, if found use it.
    # if not found, check all package path.
    # [+return+] fullpath list of all packages
    def self.read_cache_or_find_all
      if File.exists?(@@cache_path)
        f = File.open(@@cache_path)
        root_line = f.gets.chop
        package_path_line = f.gets.chop
        if root_line == "#ROS_ROOT=#{ENV['ROS_ROOT']}" and
            package_path_line == "#ROS_PACKAGE_PATH=#{ENV['ROS_PACKAGE_PATH']}"
          packages = {}
          while line = f.gets
            packages[File.basename(line.chop)] = line.chop
          end
          packages
        else
          self.find_all_packages
        end
      else
        self.find_all_packages
      end
    end

    ##
    # search all packages that has manifest.xml
    # [+packages+] current found packages
    # [+roots+] root directories for searching
    # [+return+] fullpath list of all packages
    def self.find_all_packages(packages={}, roots=ENV['ROS_PACKAGE_PATH'].split(':').push(ENV['ROS_ROOT']))
      roots.each do |root|
        if File.exists?("#{root}/manifest.xml")
          packages[File.basename(root)] = root
        else
          Dir.foreach(root) do |path|
            if path != "." and path != ".."
              full_path = "#{root}/#{path}"
              if File.directory?(full_path)
                self.find_all_packages(packages, [full_path])
              end
            end
          end
        end
      end
      packages
    end

    ##
    # all package path hash
    #
    @@all_packages = self.read_cache_or_find_all


    ##
    # get the depend packages of the arg
    # [+package+] find depends packages of this package
    # [+packages+] current found depends
    def self.depends(package, packages=[])
      file = File.open("#{@@all_packages[package]}/manifest.xml")
      doc = REXML::Document.new(file)
      doc.elements.each('/package/depend') do |element|
        depend_package = element.attributes['package']
        if not packages.include?(depend_package)
          packages.push(depend_package)
          self.depends(depend_package, packages)
        end
      end
      packages
    end


    ##
    # get the current program's package
    # [+return+] name of running programs's package
    def self.find_this_package
      path = File::dirname(File.expand_path($PROGRAM_NAME))
      while path != '/'
        if File.exists?("#{path}/manifest.xml")
          return File::basename(path)
        end
        path = File::dirname(path)
      end
      nil
    end

    ##
    # add package's [lib/, msg_gen/ruby, srv_gen/ruby] to '$:'.
    # this enables load ruby files easily
    #
    def self.add_path_of_package(package)
      path = @@all_packages[package]
      ["#{path}/msg_gen/ruby", "#{path}/srv_gen/ruby", "#{path}/lib"].each do |path|
        if File.exists?(path)
          if not $:.include?(path)
            $:.push(path)
          end
        end
      end
    end

    ##
    # add [lib/, msg_gen/ruby, srv_gen/ruby] dirs of all depend packages
    # to RUBYLIB, if the directory exists
    #
    def self.add_path_with_depend_packages(package)
      add_path_of_package(package)
      Package::depends(package).each do |pack|
        add_path_of_package(pack.chop)
      end
    end

  end

  ##
  # load manifest and add all dependencies
  #
  def self.load_manifest(package)
    ROS::Package.add_path_with_depend_packages(package)
  end
end