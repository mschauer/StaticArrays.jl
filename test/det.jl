@testset "Determinant" begin
    @test det(@SMatrix [1]) == 1
    @test logdet(@SMatrix [1]) == 0.0
    @test det(@SMatrix [0 1; 1 0]) == -1
    @test logdet(@SMatrix Complex{Float64}[0 1; 1 0]) == log(det(@SMatrix Complex{Float64}[0 1; 1 0]))
    @test det(eye(SMatrix{3,3})*im) == det(eye(3,3)*im)
    
    @test det(@SMatrix [0 1 0; 1 0 0; 0 0 1]) == -1
    m = [0.570085  0.667147  0.264427  0.561446
         0.115197  0.141744  0.83314   0.0457302
         0.249238  0.841643  0.809544  0.908978
         0.72068   0.6155    0.210278  0.607331]
    @test det(SMatrix{4,4}(m)) ≈ det(m)
    #triu/tril
    @test det(@SMatrix [1 2; 0 3]) == 3
    @test det(@SMatrix [1 2 3 4; 0 5 6 7; 0 0 8 9; 0 0 0 10]) == 400.0
    @test logdet(@SMatrix [1 2 3 4; 0 5 6 7; 0 0 8 9; 0 0 0 10]) ≈ log(400.0)
    @test @inferred(det(ones(SMatrix{10,10,Complex{Float64}}))) == 0

    # Unsigned specializations , compare to Base
    M = @SMatrix [1 2 3 4; 200 5 6 7; 0 0 8 9; 0 0 0 10]
    for sz in (2,3,4), typ in (UInt8,UInt16,UInt32,UInt64)
        Mtag = SMatrix{sz,sz,typ}(M[1:sz,1:sz])
        @test det(Mtag) == det(Array(Mtag))
    end

    @test_throws DimensionMismatch det(@SMatrix [0; 1])
end
