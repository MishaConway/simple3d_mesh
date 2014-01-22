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

    def add_face points, reuse_existing_points = false
      points.each do |pt|
        pt = Simple::Vertex.new *pt if pt.kind_of? Array
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


    def smooth_normals!
      indices_to_face_normals = Array.new vertices.size
      for i in 0..vertices.size-1
        indices_to_face_normals[i] = []
      end

      for a in 0..num_triangles-1
        indices_for_triangle(a).each do |vertex_index|
          face_normal = Geo3d::Triangle.new(*indices_for_triangle(i).map { |index| vertices[index].position }).normal
          indices_to_face_normals[vertex_index] << face_normal
        end
      end

      for i in 0..vertices.size-1
        face_normals = indices_to_face_normals[i]
        vertices[i].normal = face_normals.inject(:+) / face_normals.size.to_f
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

        v1 = position i1
        v2 = position i2
        v3 = position i3

        w1 = texcoord i1
        w2 = texcoord i2
        w3 = texcoord i3

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

        n = normals a
        t = tan1[a]

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