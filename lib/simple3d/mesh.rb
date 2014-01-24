module Simple3d
  class Mesh
    attr_accessor :indices
    attr_accessor :vertices

    def initialize options = {}
      @indices = options[:indices]
      if @indices.nil? && options[:vertices]
        options[:vertices].each_slice(3) do |points|
          add_face points, options[:reuse_existing_points]
        end
      else
        @vertices = options[:vertices]
      end

      @indices ||= []
      @vertices ||= []
    end

    def self.from_file filename
      m = self.new

      w = Wavefront::File.new filename
      w.compute_vertex_buffer.each_slice(3) do |slice|
        m.add_face slice.map{|wv| wv.position.to_a + [wv.tex.x, wv.tex.y] + wv.normal.to_a }
      end

      m
    end

    def add_face points, reuse_existing_points = true
      if points.size > 4
        raise "faces with more than four points currently not supported"
      elsif points.size == 4
        add_face [points[0], points[1], points[3]]
        add_face [points[3], points[1], points[2]]
      else
        points.each do |pt|
          pt = Vertex.new *pt if pt.kind_of? Array
          similar_vertex_index = if reuse_existing_points
                                   find_similar_vertex pt
                                 else
                                   nil
                                 end
          if similar_vertex_index
            @indices << similar_vertex_index
          else
            @vertices << pt
            @indices << @vertices.size - 1
          end
        end
      end
    end


    def find_similar_vertex v
      vertices.each_with_index do |vt, i|
        return i if vt.position == v.position && vt.texcoord == v.texcoord
      end
      nil
    end

    def collapse_similar_vertices!
      faces = indices.each_slice(3)

      old_vertices = @vertices
      old_indices = @indices
      @vertices = @indices = nil


    end

    def num_triangles
      indices.size / 3
    end

    def renderable_vertices
      indices.map do |i|
        vertices[i]
      end
    end

    def indices_for_triangle i
      [indices[i*3], indices[i*3+1], indices[i*3+2]]
    end

    def vertices_for_triangle i
      indices_for_triangle(i).map { |index| vertices[index] }
    end

    def triangle i
      Geo3d::Triangle.new *(vertices_for_triangle(i).map(&:position))
    end


    def smooth_normals!
      indices_to_face_normals = Array.new vertices.size
      for i in 0..vertices.size-1
        indices_to_face_normals[i] = []
      end

      for a in 0..num_triangles-1
        tri = triangle a
        indices_for_triangle(a).each do |vertex_index|
          face_normal = tri.normal
          indices_to_face_normals[vertex_index] << face_normal
        end
      end

      for i in 0..vertices.size-1
        face_normals = indices_to_face_normals[i]
        vertices[i].normal = face_normals.inject(:+).normalize
      end
    end

    def calculate_tangents!
      tan1 = Array.new vertices.size
      tan2 = Array.new vertices.size
      for i in 0..vertices.size-1
        tan1[i] = Geo3d::Vector.new
        tan2[i] = Geo3d::Vector.new
      end

      for a in 0..num_triangles-1
        i1, i2, i3 = indices_for_triangle a

        v1 = vertices[i1].position
        v2 = vertices[i2].position
        v3 = vertices[i3].position

        w1 = vertices[i1].texcoord
        w2 = vertices[i2].texcoord
        w3 = vertices[i3].texcoord

        x1 = v2.x - v1.x
        x2 = v3.x - v1.x
        y1 = v2.y - v1.y
        y2 = v3.y - v1.y
        z1 = v2.z - v1.z
        z2 = v3.z - v1.z

        s1 = w2.x - w1.x
        s2 = w3.x - w1.x
        t1 = w2.y - w1.y
        t2 = w3.y - w1.y

        r = 1.0 / (s1 * t2 - s2 * t1)
        sdir = Geo3d::Vector.new (t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r
        tdir = Geo3d::Vector.new (s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r

        tan1[i1] += sdir
        tan1[i2] += sdir
        tan1[i3] += sdir

        tan2[i1] += tdir
        tan2[i2] += tdir
        tan2[i3] += tdir
      end

      for a in 0..vertices.size-1

        n = vertices[a].normal
        t = tan1[a]

        puts "n is #{n.inspect}"
        puts "t is #{t.inspect}"

        # Gram-Schmidt orthogonalize
        vertices[a].tangent = (t - n * n.dot(t)).normalize

        # Calculate handedness
        # tangent(a).w = (Dot(Cross(n, t), tan2[a]) < 0.0F) ? -1.0F : 1.0F;
        vertices[a].tangent.w = n.cross(t).dot(tan2[a]) < 0.0 ? -1.0 : 1.0
      end
    end


    def self.unit_cube
      cube = self.new
      cube.add_face [[1, -1, -1], [1, -1, 1], [-1, -1, 1], [-1, -1, -1]]
      cube.add_face [[1, 1, -1], [-1, 1, -1], [-1, 1, 1], [1, 1, 1]]
      cube.add_face [[1, -1, -1], [1, 1, -1], [1, 1, 1], [1, -1, 1]]
      cube.add_face [[1, -1, 1], [1, 1, 1], [-1, 1, 1], [-1, -1, 1]]
      cube.add_face [[-1, -1, 1], [-1, 1, 1], [-1, 1, -1], [-1, -1, -1]]
      cube.add_face [[1, 1, -1], [1, -1, -1], [-1, -1, -1], [-1, 1, -1]]
      cube
    end

  end
end