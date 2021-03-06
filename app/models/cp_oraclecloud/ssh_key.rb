module CpOraclecloud
  class SshKey
    include ActiveModel::Validations
    include ActiveModel::Conversion
    extend ActiveModel::Naming

    attr_accessor :id, :uri, :enabled, :key, :name

    validates :enabled, inclusion: ["true", "false"]
    validates :key, :presence => true
    validates :name, :presence => true

    def initialize(attributes = {})
      if !attributes[:name].blank?
        regex = attributes[:name].match(/\/.*\/(.*)/)
        if regex && regex.length > 1
          clean_name = regex[1]
          attributes[:id] = clean_name
          attributes[:name] = clean_name
        end
      end
      attributes.each do |field, value|
        send("#{field}=", value)
      end
    end

    def to_s
      name
    end

    def to_model
      self
    end

    def persisted?
      !id.blank?
    end

    def self.all
      result = []
      connection.ssh_keys.each { |k| result.push(CpOraclecloud::SshKey.new(k.attributes))}
      result
    end

    def self.find_by_id(id)
      data = connection.ssh_keys.get(id)
      CpOraclecloud::SshKey.new(data.attributes)
    end

    def self.create(params)
      connection.ssh_keys.create(:name => params[:name],
                                 :enabled => params[:enabled],
                                 :key => params[:key])
    end

    def update(params)
      fog_key = self.class.connection.ssh_keys.get(id)

      [:name, :enabled, :key].each do |field|
        fog_key.attributes[field.to_sym] = params[field.to_sym]
      end
      fog_key.update
    end

    def self.delete(id)
      connection.ssh_keys.get(id).destroy
    end

    def self.connection
      @connection ||= Fog::Compute.new(
        :provider => 'OracleCloud',
        :oracle_username => CpOraclecloud.username,
        :oracle_password => CpOraclecloud.password,
        :oracle_domain => CpOraclecloud.domain,
        :oracle_compute_api => CpOraclecloud.compute_api
        )
    end
  end
end