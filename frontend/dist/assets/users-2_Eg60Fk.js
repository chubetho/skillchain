import{d as p,l as _,D as v,r as f,n as h,u as l,o as r,h as i,L as I,a as T,w as t,ai as J,f as s,m as L,aj as q,A,a2 as E,v as z,x as G,y as M,a0 as P,a3 as K,G as O,B as u,F as Q,E as W,C as k}from"./index-0LozPYKy.js";import{C as X,_ as Y}from"./BaseSearch.vue_vue_type_script_setup_true_lang-K-zY4Dt_.js";import"./Input.vue_vue_type_script_setup_true_lang-CRnS55Ql.js";import"./Label.vue_vue_type_script_setup_true_lang-uDSuRFS9.js";const Z={class:"w-full overflow-auto"},ee=p({__name:"Table",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("div",Z,[v("table",{class:h(l(i)("w-full caption-bottom text-sm",e.class))},[f(a.$slots,"default")],2)]))}}),se=p({__name:"TableBody",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("tbody",{class:h(l(i)("[&_tr:last-child]:border-0",e.class))},[f(a.$slots,"default")],2))}}),te=p({__name:"TableCell",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("td",{class:h(l(i)("p-4 align-middle [&:has([role=checkbox])]:pr-0",e.class))},[f(a.$slots,"default")],2))}}),ae=p({__name:"Checkbox",props:{defaultChecked:{type:Boolean},checked:{type:[Boolean,String]},disabled:{type:Boolean},required:{type:Boolean},name:{},value:{},id:{},asChild:{type:Boolean},as:{}},emits:["update:checked"],setup(o,{emit:e}){const g=I(o,e);return($,y)=>(r(),T(l(q),L(l(g),{class:l(i)("peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground",$.$attrs.class??"")}),{default:t(()=>[s(l(J),{class:"flex h-full w-full items-center justify-center text-current"},{default:t(()=>[s(l(X),{class:"h-4 w-4"})]),_:1})]),_:1},16,["class"]))}}),oe=p({__name:"TableHeader",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("thead",{class:h(l(i)("[&_tr]:border-b",e.class))},[f(a.$slots,"default")],2))}}),le=p({__name:"TableRow",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("tr",{class:h(l(i)("border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted",e.class))},[f(a.$slots,"default")],2))}}),ne=p({__name:"TableHead",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("th",{class:h(l(i)("h-12 px-4 text-left align-middle font-medium text-muted-foreground [&:has([role=checkbox])]:pr-0",e.class))},[f(a.$slots,"default")],2))}}),re=p({__name:"TableCaption",props:{class:{}},setup(o){const e=o;return(a,n)=>(r(),_("caption",{class:h(l(i)("mt-4 text-sm text-muted-foreground",e.class))},[f(a.$slots,"default")],2))}}),ce={class:"py-10"},ue={class:"py-8 space-y-8"},de=v("h1",{class:"text-4xl"}," users ",-1),fe=p({__name:"users",async setup(o){let e,a;const n=A(""),g=E(n,500),$=z(),y=([e,a]=G(()=>$.getUserFactory()),e=await e,a(),e),x=M([]),B=P(()=>g.value?x.value.filter(m=>m.userName.toLowerCase().includes(g.value.toLowerCase())):x.value);async function N(){const m=await y.getAllUsers();x.value=m.map(c=>({owner:c[0],userName:c[1],isJudge:c[2],jobIds:c[3].map(Number),escrowIds:c[4].map(Number)}))}K(()=>{N()});async function U(m,c){c?await y.setJudge(m):await y.unsetJudge(m)}return(m,c)=>{const V=Y,j=re,b=ne,C=le,R=oe,S=ae,w=te,D=se,F=ee;return r(),_("div",null,[v("div",ce,[s(V,{modelValue:l(n),"onUpdate:modelValue":c[0]||(c[0]=d=>O(n)?n.value=d:null),placeholder:"search for username or keyword"},null,8,["modelValue"])]),v("div",ue,[de,s(F,null,{default:t(()=>[s(j,null,{default:t(()=>[u("a list of all users")]),_:1}),s(R,null,{default:t(()=>[s(C,null,{default:t(()=>[s(b,{class:""},{default:t(()=>[u(" reviewer ")]),_:1}),s(b,null,{default:t(()=>[u("username")]),_:1}),s(b,null,{default:t(()=>[u("address")]),_:1}),s(b,null,{default:t(()=>[u("jobs")]),_:1}),s(b,null,{default:t(()=>[u("escrows")]),_:1})]),_:1})]),_:1}),s(D,null,{default:t(()=>[(r(!0),_(Q,null,W(l(B),d=>(r(),T(C,{key:d.userName},{default:t(()=>[s(w,{class:""},{default:t(()=>[s(S,{"default-checked":d.isJudge,"onUpdate:checked":H=>U(d.owner,H)},null,8,["default-checked","onUpdate:checked"])]),_:2},1024),s(w,{class:"font-medium"},{default:t(()=>[u(k(d.userName),1)]),_:2},1024),s(w,{class:"tracking-wider"},{default:t(()=>[u(k(d.owner),1)]),_:2},1024),s(w,null,{default:t(()=>[u(k(d.jobIds.length),1)]),_:2},1024),s(w,null,{default:t(()=>[u(k(d.escrowIds.length),1)]),_:2},1024)]),_:2},1024))),128))]),_:1})]),_:1})])])}}});export{fe as default};
