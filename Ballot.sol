pragma solidity ^0.4.16;

//委托投票

contract Ballot {

    //创建选民的结构体
    struct Voter{
        uint weight;//记票的权重
        bool voted;//该人是否已投票
        address delegate;//被委托人
        uint vote;//投票提案的索引
    }

    //提案的结构体
    struct Proposal{
        bytes32 name;//简称
        uint voteCount;//得票数
    }

    address public chairperson;

    //为每一个可能的地址存储一个Voter；
    mapping(address => Voter) public voters;

    //声明一个动态数组
    Proposal[] public proposal;

    function Ballot(bytes32[] proposalNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for(uint i = 0;i < proposalNames.length ; i++){
            proposals.push(Proposal({name:proposalNames[i],voteCount:0}));
        }
    }
    
    //授权voter进行表决，只有chairperson可以调用
    function giveRightToVote(address voter) public {
        require((msg.sender == chairperson) &&
                !voters[voter].voted &&
                (voters[voter].weight==0));
        voters[voter].weight = 1;
    }

    //把你的投票委托到投票者'to'
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);

        //委托给自己是不允许的
        require(to != msg.sender);
        while(voter[to].delegate != address(0)){
            to = voters[to].delegate;

            require(to != msg.sender);
        }

        sender.voted = true;
        sender.delegate = to;
        Voter storage delegate_ = voters[to];

        if(delegate_.voted){
            //若被委托者已经投票了，直接增加得票数
            proposals[delegate_.vote].voteCount += sender.weight;
        }else{
            //若被委托者还没投票，增加委托者的权重
            delegate_.weight += sender.weight;
        }
    }

    //把你的票包括委托给你的票投给提案
    function vote(uint proposal) public {
        Voter storage sender = voters[msg.sender];
        require(!sender.voted);
        sender.voted = true;
        sender.vote = proposal;

        //如果proposal超过了数组的范围，则会自动抛出异常，并恢复所有的改动
        proposals[proposal].voteCount += sender.weight;
    }

    //结合之前所有的投票，计算出最终胜出的提案
    function winningProposal() public view returns (uint winningProposal) {
        uint winningVoteCount = 0;

        for(uint p = 0; p < proposals.length;p++){
            if(proposals[p].voteCount > winningVoteCount){
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }
    }

    //调用winningProposal() 函数以获取提案数组中获胜者的索引，并以此返回获胜者的名称
    function winnerName() public view returns (bytes32 winnerName_){
        winnerName_ = proposals[winningProposal()].name;
    }
}

//优化点:目前为了把投票权分配给所有的参与者，需要执行很多交易，思考更好的方法
