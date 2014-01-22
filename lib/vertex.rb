module Simple3d
  class Vertex
    attr_accessor :position
    attr_accessor :texcoord
    attr_accessor :normal
    attr_accessor :tangent


    def initialize *args
      @position = Geo3d::Vector.point( args[0], args[1], args[2] )
      @texcoord = Geo3d::Vector.point( args[3], args[4 ])

    end

    def bitangent
      normal.cross tangent
    end
  end
end