(* ::Package:: *)

(* Just attempt to verify this: http://math.stackexchange.com/questions/115743/question-about-a-rotating-cube *)

heron[side1_,side2_,base_]:=Module[{p,s},( 
    p=(side1+side2+base)/2;
    s=Sqrt[p (p-side1)(p-side2)(p-base)])]


getHeight[side1_,side2_,base_]:=Module[{cos,sin,h},( 
    cos=(side1*side1+base*base-side2*side2)/(2*side1*base);
    sin=Sqrt[1-cos*cos];
    h=side1*sin)]


makeTwoSides[t_]:={Sqrt[1+t*t],Sqrt[1+(1-t)*(1-t)]}


curve=getHeight @@ (makeTwoSides[t]~Join~{Sqrt[3]})//
    Simplify[#,0<=t<=1]&


Plot[curve,{t,0,1}]
