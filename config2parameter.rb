# -*- coding: utf-8 -*-

def conf2param(filename)

  require 'fileutils'
  require 'json'
  require 'kconv'
  require 'spreadsheet'
  require 'date'

  ########################################
  ### config to json
  ########################################

  config = Array.new

  config[0] = "{"
  f = File.open(filename,"r")
  f.each_line.with_index do |each,i|
    case each
    ### config firewall
    when /(config\sfirewall\spolicy)/,/(config\sidentity-based-policy)/
      config[i+1] = "\"#{$1}\":\s{"
    ### edit number
    when /(edit\s\d+)/
      config[i+1] = "\"#{$1}\":\s{" 
    ### set object
    when /set\s([a-zA-Z0-9\-_]+)\s(\".+\")/
      if each.count("\"") == 2 then
        config[i+1] = "\"#{$1}\"\s:\s#{$2},"
      ### pbject is multiple
      else
        config[i+1] = "\"#{$1}\"\s:#{$2.gsub(/\"\s\"/,"$")},"
      end
    ### set object(type is choise)
    when /set\s([a-zA-Z0-9\-_]+)\s([a-zA-Z0-9\-_]+)/
      config[i+1] = "\"#{$1}\"\s:\s\"#{$2}\","
    ### next
    when /next/
      config[i+1] = "},"
    ### end
    when /end/
      config[i+1] = "}"
    end
  end

  config[config.length] = "}"

  ### }, to }
  config.each.with_index do |each,i|
    if (each == "},") or (each == "}") then
      config[i-1] = config[i-1].gsub(/,/,"")
    end
  end

  ### test code
  #puts "test output"
  #puts config

  ########################################
  ### json to paramete
  ########################################

  parsed_json = JSON.parse(config.join())

  ### extract the configuration section

  section = Array.new
  parsed_json['config firewall policy'].keys.each do |each|
    section = section + parsed_json['config firewall policy'][each].keys
  end

  workbook = Spreadsheet::Workbook.new
  worksheet = workbook.create_worksheet(:name=>"Paramater")

  category = Array[
    "id",
    "srcintf",
    "srcaddr",
    "dstintf",
    "dstaddr",
    "service",
    "schedule",
    "action",
    "nat",
    "ippool",
    "log",
    "utm",
    "protocol_profile",
    "status"
  ]

  category.each.with_index do |each,i|
    worksheet[0,i] = each
  end

  parsed_json['config firewall policy'].keys.each.with_index do |each,line|
    id = each.gsub(/edit\s/,"")

    srcintf = parsed_json['config firewall policy'][each]['srcintf']
    srcaddr = parsed_json['config firewall policy'][each]['srcaddr']
    dstintf = parsed_json['config firewall policy'][each]['dstintf']
    dstaddr = parsed_json['config firewall policy'][each]['dstaddr']
    service = parsed_json['config firewall policy'][each]['service']
    schedule = parsed_json['config firewall policy'][each]['schedule']
    action = parsed_json['config firewall policy'][each]['action']
    status = parsed_json['config firewall policy'][each]['status']
    if status == "disable" then
      status = "OFF"
    else
      status = "ON"
    end

    logtraffic = parsed_json['config firewall policy'][each]['logtraffic']
    if logtraffic == "enable" then
      logtraffic = "ON"
    else 
      logtraffic = "OFF"
    end

    nat = parsed_json['config firewall policy'][each]['nat']
    ippool = parsed_json['config firewall policy'][each]['ippool']
    poolname = parsed_json['config firewall policy'][each]['poolname']
    if ippool == "enable" then
      ippool = poolname
    end

    utm = parsed_json['config firewall policy'][each]['utm-status']
    av = parsed_json['config firewall policy'][each]['av-profile']
    webfilter = parsed_json['config firewall policy'][each]['webfilter-profile']
    spamfilter = parsed_json['config firewall policy'][each]['spamfilter-profile']
    ips = parsed_json['config firewall policy'][each]['ips-sensor']
    application = parsed_json['config firewall policy'][each]['application-list']

    if utm == "enable" then
      if not av.nil? then
       utm_profile = "#{utm_profile}AV : #{av}$"
      end

      if not webfilter.nil? then
        utm_profile = "#{utm_profile}WEB : #{webfilter}$"
      end

      if not spamfilter.nil? then
        utm_profile = "#{utm_profile}SPAN : #{spamfilter}$"
      end

      if not ips.nil? then
        utm_profile = "#{utm_profile}IPS : #{ips}$"
      end

      if not application.nil? then
        utm_profile = "#{utm_profile}APC : #{application}$"
      end

      if not utm_profile.nil? then
        utm_profile.chop!
      end
    end

    profile_protocol = parsed_json['config firewall policy'][each]['profile-protocol-options']

    policy = Array[
      id,
      srcintf,
      srcaddr,
      dstintf,
      dstaddr,
      service,
      schedule,
      action,
      nat,
      ippool,
      logtraffic,
      utm_profile,
      profile_protocol,
      status
    ]

    policy.each.with_index do |each,row|
      if each.nil? then
        each = "-"
      else
        each.gsub!(/\$/,"\n")
      end
      worksheet[line+1,row] = each
    end

  end

  output_filename = filename.gsub(/\.\/config\//,"")
  workbook.write("./param/Parameter_#{output_filename}.xls")
  return "Parameter_#{output_filename}.xls"
end
