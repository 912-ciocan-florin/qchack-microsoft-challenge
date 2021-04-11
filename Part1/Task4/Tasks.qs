namespace QCHack.Task4 {
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Logical;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //

    operation ValidTriangle (a : Qubit, b : Qubit, c : Qubit, output : Qubit) : Unit is Adj+Ctl {
        
        use aux = Qubit[2];
        
        CNOT(a, aux[0]);
        CNOT(b, aux[0]);
        X(aux[0]);

        CNOT(b, aux[1]);
        CNOT(c, aux[1]);
        X(aux[1]);
        
        ApplyAnd(aux[0], aux[1], output);
        X(output);
        
        CNOT(a, aux[0]);
        CNOT(b, aux[0]);
	    X(aux[0]);

        CNOT(b, aux[1]);
        CNOT(c, aux[1]);
        X(aux[1]);
    }

    function Is_Edge(t1 : (Int, Int), edges : (Int, Int)[], index : Int) : Int {
        let (a, b) = t1;
        
        mutable n = Length(edges);
        for i in index .. n-1 {
            let (e_a, e_b) = edges[i];
            if ((a == e_a and b == e_b) or (a == e_b and b == e_a)) {
                return i;
            }
        }
        
        return -1;
    }
    
    function Triangles(edges : (Int, Int)[], V : Int) : ((Int, Int, Int)[], Int) {
        
        mutable triangles = new((Int, Int, Int))[Length(edges)];
        mutable triangle_index = 0;
        mutable n = Length(edges);
        for index in 0 .. n-1 {
            for v in 0 .. V - 1 {
                let (a, b) = edges[index];
                let x = Is_Edge((a, v), edges, index);
                let y = Is_Edge((b, v), edges, index);
                if (x != -1 and y != -1){
                    set triangles w/= triangle_index <- (index, x, y);
                    set triangle_index = triangle_index + 1;
                }
            }
        }

        return (triangles, triangle_index);
    }

    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        
        let (triangles, nb_triangles) = Triangles(edges, V);
        use triangle_states = Qubit[nb_triangles];
        within{
            for i in 0 .. nb_triangles-1 {
                let (a, b, c) = triangles[i];
                ValidTriangle(colorsRegister[a], colorsRegister[b], colorsRegister[c], triangle_states[i]);
            }
        }
        apply{
            ApplyControlledOnInt(2 ^ nb_triangles - 1, X, triangle_states, target);
        }
    }
}

